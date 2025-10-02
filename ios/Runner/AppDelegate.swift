import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    GeneratedPluginRegistrant.register(with: self)

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    let alarmChannel = FlutterMethodChannel(name: "alarm_channel",
                                            binaryMessenger: controller.binaryMessenger)

    alarmChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "setAlarms":
        print("iOS: setAlarms called")
        result(nil) 
        
      case "requestExactAlarmPermission":
        print("iOS: requestExactAlarmPermission called (not required on iOS)")
        result(nil) 

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
