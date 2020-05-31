import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyD8TDpgqTxyKLXO2zOUv-FTRWIpqjRuyKA")
    GeneratedPluginRegistrant.register(with: self)
   //if #available(iOS 10.0, *) {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  //}
    // [GeneratedPluginRegistrant registerWithRegistry:self];
    // [GMSServices provideAPIKey:@"{{AIzaSyD8TDpgqTxyKLXO2zOUv-FTRWIpqjRuyKA}}"];
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

// if #available(iOS 10.0, *) {
  // UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
// }
}
