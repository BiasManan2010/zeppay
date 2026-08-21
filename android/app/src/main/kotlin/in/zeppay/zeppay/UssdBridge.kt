package `in`.zeppay.zeppay

import android.accessibilityservice.AccessibilityServiceInfo
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.view.accessibility.AccessibilityManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class UssdBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, UssdAccessibilityService.UssdSessionListener {

    private val channel = MethodChannel(messenger, CHANNEL)
    private var sessionActive = false

    init {
        channel.setMethodCallHandler(this)
        UssdAccessibilityService.listener = this
    }

    fun dispose() {
        if (UssdAccessibilityService.listener === this) {
            UssdAccessibilityService.listener = null
        }
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())
            "canDrawOverlays" -> result.success(Settings.canDrawOverlays(activity))
            "openAccessibilitySettings" -> {
                activity.startActivity(
                    Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    },
                )
                result.success(true)
            }
            "openOverlaySettings" -> {
                activity.startActivity(
                    Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}"),
                    ).apply {
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    },
                )
                result.success(true)
            }
            "startSession" -> {
                sessionActive = true
                result.success(true)
            }
            "endSession" -> {
                sessionActive = false
                result.success(true)
            }
            "submitReply" -> {
                val reply = call.argument<String>("reply").orEmpty()
                if (reply.isNotEmpty()) {
                    UssdAccessibilityService.injectReply(reply)
                }
                result.success(true)
            }
            "showOverlay" -> {
                val prompt = call.argument<String>("prompt").orEmpty()
                val pinStep = call.argument<Boolean>("isPinStep") ?: false
                UssdOverlayActivity.show(activity, prompt, pinStep)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    override fun onUssdMessage(message: String, isPinStep: Boolean) {
        if (!sessionActive) return
        channel.invokeMethod(
            "ussdMessage",
            mapOf("text" to message, "isPinStep" to isPinStep),
        )
        UssdOverlayActivity.show(activity, message, isPinStep)
    }

    override fun onUssdSessionEnded() {
        sessionActive = false
        channel.invokeMethod("ussdEnded", null)
    }

    private fun isAccessibilityEnabled(): Boolean {
        val manager =
            activity.getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
        val enabled = manager.getEnabledAccessibilityServiceList(
            AccessibilityServiceInfo.FEEDBACK_GENERIC,
        )
        return enabled.any { it.resolveInfo.serviceInfo.packageName == activity.packageName }
    }

    companion object {
        const val CHANNEL = "in.zeppay/ussd"
    }
}
