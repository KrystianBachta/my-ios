import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Prośba o zgodę na śledzenie (ATT) wymagana przez Apple
                    ATTrackingManager.requestTrackingAuthorization { status in
                        // Inicjalizacja reklam po odpowiedzi użytkownika
                        GADMobileAds.sharedInstance().start(completionHandler: nil)
                    }
                }
        }
    }
}
