import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    FlutterMethodChannel(name: "in.zeppay/telephony", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        if call.method == "getNetworkInfo" {
          result([
            "operator": "ios",
            "isJio": false,
            "networkType": "n/a",
            "recommendedRail": "upiIntent",
            "ussdSupported": false,
            "platform": "ios",
          ])
        } else if call.method == "dial" {
          result(FlutterError(code: "ios", message: "Offline rails are Android-only", details: nil))
        } else {
          result(nil)
        }
      }
  }
}
