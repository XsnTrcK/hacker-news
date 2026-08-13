import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    let appIconChannel = FlutterMethodChannel(
      name: "app_icons", binaryMessenger: controller.binaryMessenger)
    appIconChannel.setMethodCallHandler { (call, result) in
      guard call.method == "setIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
            let icon = args["icon"] as? String
      else {
        result(FlutterError(code: "invalid_args", message: "Missing icon", details: nil))
        return
      }

      // Maps the `icon` selection to the alternate icon name registered
      // under CFBundleAlternateIcons in Info.plist; `nil` restores the
      // primary (default) app icon.
      let alternateIconName: String?
      switch icon {
      case "icon":
        alternateIconName = nil
      case "crayons":
        alternateIconName = "Crayons"
      case "lines":
        alternateIconName = "Lines"
      default:
        result(FlutterError(code: "invalid_icon", message: "Unknown icon", details: nil))
        return
      }

      UIApplication.shared.setAlternateIconName(alternateIconName) { error in
        if let error = error {
          result(FlutterError(
            code: "set_icon_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
