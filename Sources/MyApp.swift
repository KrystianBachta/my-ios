import SwiftUI
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Uruchomienie SDK od Google AdMob
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        return true
    }
}

@main
struct MyApp: App {
    // Podpięcie AppDelegate do cyklu życia aplikacji SwiftUI
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
