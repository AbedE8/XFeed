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
    // [GeneratedPluginRegistrant registerWithRegistry:self];
    // [GMSServices provideAPIKey:@"{{AIzaSyD8TDpgqTxyKLXO2zOUv-FTRWIpqjRuyKA}}"];
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
