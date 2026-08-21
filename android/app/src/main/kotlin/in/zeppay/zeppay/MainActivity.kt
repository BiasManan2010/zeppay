package `in`.zeppay.zeppay

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var telephony: TelephonyBridge? = null
    private var ussd: UssdBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        telephony = TelephonyBridge(this, messenger)
        ussd = UssdBridge(this, messenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        ussd?.dispose()
        ussd = null
        telephony?.dispose()
        telephony = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
