package `in`.zeppay.zeppay

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

/**
 * Android-only offline UPI rails:
 * - Carrier detection via TelephonyManager.getSimOperatorName()
 * - Auto-dial *99# USSD or 123PAY IVR via Intent.ACTION_CALL
 * - Call-end detection via TelephonyCallback / PhoneStateListener
 */
class TelephonyBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val method = MethodChannel(messenger, CHANNEL)
    private val events = EventChannel(messenger, EVENT_CHANNEL)
    private val telephony: TelephonyManager =
        activity.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

    private var eventSink: EventChannel.EventSink? = null
    private var lastState = TelephonyManager.CALL_STATE_IDLE
    private var listening = false
    private var modernCallback: TelephonyCallback? = null

    @Suppress("DEPRECATION")
    private val legacyListener = object : PhoneStateListener() {
        @Deprecated("Deprecated in Java")
        override fun onCallStateChanged(state: Int, phoneNumber: String?) {
            handleCallState(state)
        }
    }

    init {
        method.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getNetworkInfo" -> result.success(networkInfo())
            "requestPermissions" -> {
                ActivityCompat.requestPermissions(
                    activity,
                    arrayOf(
                        Manifest.permission.CALL_PHONE,
                        Manifest.permission.READ_PHONE_STATE,
                    ),
                    991,
                )
                result.success(true)
            }
            "hasCallPermission" -> result.success(
                ActivityCompat.checkSelfPermission(activity, Manifest.permission.CALL_PHONE) ==
                    PackageManager.PERMISSION_GRANTED,
            )
            "dial" -> {
                val raw = call.argument<String>("number")
                if (raw.isNullOrBlank()) {
                    result.error("bad_args", "number required", null)
                    return
                }
                try {
                    dial(raw)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("dial_failed", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        startListening()
    }

    override fun onCancel(arguments: Any?) {
        stopListening()
        eventSink = null
    }

    fun dispose() {
        stopListening()
        method.setMethodCallHandler(null)
        events.setStreamHandler(null)
    }

    private fun networkInfo(): Map<String, Any?> {
        val operator = telephony.simOperatorName ?: telephony.networkOperatorName ?: ""
        val normalized = operator.lowercase(Locale.US)
        val isJio = normalized.contains("jio") || normalized.contains("reliance")
        val networkType = networkTypeName()
        val rail = if (isJio) "ivr" else "ussd"
        return mapOf(
            "operator" to operator,
            "isJio" to isJio,
            "networkType" to networkType,
            "simCountry" to (telephony.simCountryIso ?: ""),
            "recommendedRail" to rail,
            "ussdSupported" to (rail == "ussd"),
            "platform" to "android",
        )
    }

    @Suppress("DEPRECATION")
    private fun networkTypeName(): String {
        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return "unknown"
        }
        return when (telephony.dataNetworkType) {
            TelephonyManager.NETWORK_TYPE_NR -> "NR"
            TelephonyManager.NETWORK_TYPE_LTE -> "LTE"
            TelephonyManager.NETWORK_TYPE_HSPAP,
            TelephonyManager.NETWORK_TYPE_HSPA,
            TelephonyManager.NETWORK_TYPE_UMTS,
            -> "3G"
            TelephonyManager.NETWORK_TYPE_EDGE,
            TelephonyManager.NETWORK_TYPE_GPRS,
            -> "2G"
            else -> "unknown"
        }
    }

    private fun dial(number: String) {
        if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.CALL_PHONE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw SecurityException("CALL_PHONE not granted")
        }
        val uri = Uri.parse("tel:${Uri.encode(number)}")
        val intent = Intent(Intent.ACTION_CALL, uri)
        activity.startActivity(intent)
    }

    private fun handleCallState(state: Int) {
        val previous = lastState
        lastState = state
        val label = when (state) {
            TelephonyManager.CALL_STATE_IDLE -> "idle"
            TelephonyManager.CALL_STATE_RINGING -> "ringing"
            TelephonyManager.CALL_STATE_OFFHOOK -> "offhook"
            else -> "unknown"
        }
        val payload = hashMapOf<String, Any>(
            "state" to label,
            "ended" to (previous != TelephonyManager.CALL_STATE_IDLE &&
                state == TelephonyManager.CALL_STATE_IDLE),
        )
        Handler(Looper.getMainLooper()).post {
            eventSink?.success(payload)
        }
    }

    private fun startListening() {
        if (listening) return
        listening = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ActivityCompat.checkSelfPermission(activity, Manifest.permission.READ_PHONE_STATE) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            val cb = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) {
                    handleCallState(state)
                }
            }
            modernCallback = cb
            telephony.registerTelephonyCallback(activity.mainExecutor, cb)
        } else {
            @Suppress("DEPRECATION")
            telephony.listen(legacyListener, PhoneStateListener.LISTEN_CALL_STATE)
        }
    }

    private fun stopListening() {
        if (!listening) return
        listening = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            modernCallback?.let {
                try {
                    telephony.unregisterTelephonyCallback(it)
                } catch (_: Exception) {
                }
            }
            modernCallback = null
        } else {
            @Suppress("DEPRECATION")
            telephony.listen(legacyListener, PhoneStateListener.LISTEN_NONE)
        }
    }

    companion object {
        const val CHANNEL = "in.zeppay/telephony"
        const val EVENT_CHANNEL = "in.zeppay/call_state"
    }
}
