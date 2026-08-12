package in.zeppay.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterFragmentActivity() {
    private val methodChannelName = "in.zeppay/telephony"
    private val eventChannelName = "in.zeppay/call_state"
    private var eventSink: EventChannel.EventSink? = null
    private var sawOffhook = AtomicBoolean(false)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getNetworkInfo" -> result.success(networkInfo())
                    "requestPermissions" -> {
                        requestPerms()
                        result.success(true)
                    }
                    "hasCallPermission" -> result.success(
                        ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) ==
                            PackageManager.PERMISSION_GRANTED
                    )
                    "dial" -> {
                        val number = call.argument<String>("number")
                        if (number.isNullOrBlank()) {
                            result.error("bad_args", "number required", null)
                        } else {
                            try {
                                dial(number)
                                result.success(true)
                            } catch (e: Exception) {
                                result.error("dial_failed", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    listenCalls()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun requestPerms() {
        val needed = mutableListOf(
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.CAMERA,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            needed.add(Manifest.permission.READ_PHONE_NUMBERS)
        }
        val missing = needed.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, missing.toTypedArray(), 99)
        }
    }

    private fun networkInfo(): Map<String, Any> {
        val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        val operator = try {
            tm.simOperatorName.ifBlank { tm.networkOperatorName }
        } catch (_: SecurityException) {
            ""
        }
        val isJio = operator.contains("jio", ignoreCase = true) ||
            operator.contains("reliance", ignoreCase = true)
        val networkType = try {
            when (tm.dataNetworkType) {
                TelephonyManager.NETWORK_TYPE_LTE,
                TelephonyManager.NETWORK_TYPE_LTE_CA -> "lte"
                TelephonyManager.NETWORK_TYPE_NR -> "nr"
                TelephonyManager.NETWORK_TYPE_UMTS,
                TelephonyManager.NETWORK_TYPE_HSPA,
                TelephonyManager.NETWORK_TYPE_HSPAP -> "3g"
                TelephonyManager.NETWORK_TYPE_GPRS,
                TelephonyManager.NETWORK_TYPE_EDGE -> "2g"
                else -> "unknown"
            }
        } catch (_: SecurityException) {
            "unknown"
        }
        val ussdSupported = !isJio && networkType != "nr"
        val rail = if (ussdSupported) "ussd" else "ivr"
        return mapOf(
            "operator" to operator,
            "isJio" to isJio,
            "networkType" to networkType,
            "recommendedRail" to rail,
            "ussdSupported" to ussdSupported,
            "platform" to "android",
        )
    }

    private fun dial(number: String) {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            requestPerms()
            throw SecurityException("CALL_PHONE not granted")
        }
        sawOffhook.set(false)
        val uri = if (number.startsWith("tel:") || number.startsWith("upi:")) {
            Uri.parse(number)
        } else {
            Uri.parse("tel:${Uri.encode(number)}")
        }
        startActivity(Intent(Intent.ACTION_CALL, uri))
    }

    private fun emit(ended: Boolean, state: String) {
        runOnUiThread {
            eventSink?.success(mapOf("ended" to ended, "state" to state))
        }
    }

    private fun onCallState(state: Int) {
        when (state) {
            TelephonyManager.CALL_STATE_OFFHOOK -> sawOffhook.set(true)
            TelephonyManager.CALL_STATE_IDLE -> {
                if (sawOffhook.getAndSet(false)) {
                    emit(true, "idle")
                }
            }
            TelephonyManager.CALL_STATE_RINGING -> emit(false, "ringing")
        }
    }

    private fun listenCalls() {
        val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                return
            }
            tm.registerTelephonyCallback(
                mainExecutor,
                object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                    override fun onCallStateChanged(state: Int) {
                        onCallState(state)
                    }
                },
            )
        } else {
            @Suppress("DEPRECATION")
            tm.listen(
                object : PhoneStateListener() {
                    @Deprecated("deprecated")
                    override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                        onCallState(state)
                    }
                },
                PhoneStateListener.LISTEN_CALL_STATE,
            )
        }
    }
}
