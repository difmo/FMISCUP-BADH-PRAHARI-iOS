import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    // Alarm Channel
    let alarmChannel = FlutterMethodChannel(name: "alarm_channel", binaryMessenger: controller.binaryMessenger)
    alarmChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
        case "setAlarms":
          print("setAlarms called on iOS")
          result(nil)
        case "requestExactAlarmPermission":
          print("requestExactAlarmPermission called on iOS")
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
      }
    }

    // Developer Mode Channel
    let devModeChannel = FlutterMethodChannel(name: "com.techwings.fmiscupapp2", binaryMessenger: controller.binaryMessenger)
    devModeChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "isDeveloperModeEnabled" {
        print("isDeveloperModeEnabled called on iOS")
        result(false) // Always false on iOS
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
