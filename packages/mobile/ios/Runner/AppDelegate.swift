import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import GoogleMaps
import GooglePlaces

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }

    if let mapsKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !mapsKey.isEmpty,
       mapsKey != "$(GMS_API_KEY)",
       mapsKey != "YOUR_IOS_GOOGLE_MAPS_API_KEY" {
      GMSServices.provideAPIKey(mapsKey)
      GMSPlacesClient.provideAPIKey(mapsKey)
    } else {
      NSLog("[SingleClin] Google Maps API key is missing or uses the placeholder value. Update ios/Runner/Info.plist or Xcode build settings with a valid key.")
    }

    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
