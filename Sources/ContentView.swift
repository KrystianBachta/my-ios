import SwiftUI
import WebKit
import GoogleMobileAds

// MARK: - Zarządzanie stanem (pokazywanie banera)
class AppViewModel: ObservableObject {
    @Published var showBanner = false
}

// MARK: - Reklama przy Otwarciu Aplikacji (Natywna / App Open)
class AppOpenAdManager: NSObject, GADFullScreenContentDelegate {
    static let shared = AppOpenAdManager()
    var appOpenAd: GADAppOpenAd?
    var isShowingAd = false
    
    func loadAd() {
        // ID jednostki: Natywna
        GADAppOpenAd.load(withAdUnitID: "ca-app-pub-6681851361306996/4875578809", request: GADRequest()) { ad, error in
            self.appOpenAd = ad
            self.appOpenAd?.fullScreenContentDelegate = self
        }
    }
    
    func showAdIfAvailable() {
        if isShowingAd { return }
        guard let ad = appOpenAd,
              let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            loadAd()
            return
        }
        isShowingAd = true
        ad.present(fromRootViewController: root)
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isShowingAd = false
        appOpenAd = nil
        loadAd() // Załaduj kolejną na przyszłość
    }
}

// MARK: - WebView i Most JS -> Swift
struct WebViewWrapper: UIViewRepresentable {
    let url: URL
    @ObservedObject var viewModel: AppViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        // Rejestracja nasłuchiwania na wiadomości JavaScript z Twojej strony
        contentController.add(context.coordinator, name: "admob")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        context.coordinator.webView = webView
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if uiView.url == nil {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
    
    class Coordinator: NSObject, WKScriptMessageHandler, GADFullScreenContentDelegate {
        var parent: WebViewWrapper
        var webView: WKWebView?
        
        var interstitialAd: GADInterstitialAd?
        var rewardedAd: GADRewardedAd?
        
        init(_ parent: WebViewWrapper) {
            self.parent = parent
            super.init()
            loadInterstitial()
            loadRewarded()
        }
        
        func loadInterstitial() {
            // ID jednostki: Pełnoekranowa
            GADInterstitialAd.load(withAdUnitID: "ca-app-pub-6681851361306996/3637418675", request: GADRequest()) { ad, error in
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
            }
        }
        
        func loadRewarded() {
            // ID jednostki: Z nagrodą
            GADRewardedAd.load(withAdUnitID: "ca-app-pub-6681851361306996/9996043547", request: GADRequest()) { ad, error in
                self.rewardedAd = ad
                self.rewardedAd?.fullScreenContentDelegate = self
            }
        }
        
        // Odbieranie sygnałów od strony my.fhi.pl (JavaScript)
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "admob", let action = message.body as? String else { return }
            
            DispatchQueue.main.async {
                if action == "showBanner" {
                    self.parent.viewModel.showBanner = true
                } else if action == "hideBanner" {
                    self.parent.viewModel.showBanner = false
                } else if action == "showInterstitial" {
                    self.showInterstitialAd()
                } else if action == "showRewarded" {
                    self.showRewardedAd()
                }
            }
        }
        
        func showInterstitialAd() {
            guard let ad = interstitialAd, let root = getRootViewController() else { return }
            ad.present(fromRootViewController: root)
        }
        
        func showRewardedAd() {
            guard let ad = rewardedAd, let root = getRootViewController() else { return }
            ad.present(fromRootViewController: root) {
                // Gdy użytkownik obejrzy reklamę z nagrodą do końca (np. kawa), iOS odpala funkcję JS na Twojej stronie
                self.webView?.evaluateJavaScript("if(typeof rewardGranted === 'function') { rewardGranted(); }", completionHandler: nil)
            }
        }
        
        func getRootViewController() -> UIViewController? {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return nil }
            return scene.windows.first { $0.isKeyWindow }?.rootViewController
        }
        
        func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            if ad is GADInterstitialAd { loadInterstitial() }
            else if ad is GADRewardedAd { loadRewarded() }
        }
    }
}

// MARK: - Widok Banera Reklamowego
struct BannerView: UIViewRepresentable {
    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        // ID jednostki: Baner
        banner.adUnitID = "ca-app-pub-6681851361306996/2603538606"
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
            banner.rootViewController = root
        }
        banner.load(GADRequest())
        return banner
    }
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

// MARK: - Główny Widok Aplikacji
struct ContentView: View {
    @StateObject var viewModel = AppViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some View {
        VStack(spacing: 0) {
            WebViewWrapper(url: URL(string: "https://my.fhi.pl")!, viewModel: viewModel)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            
            // Baner wyświetla się tylko wtedy, gdy strona o to poprosi (np. w kawiarni)
            if viewModel.showBanner {
                BannerView()
                    .frame(width: 320, height: 50)
            }
        }
        .ignoresSafeArea(edges: [.top])
        .onAppear {
            AppOpenAdManager.shared.loadAd() // Załaduj reklamę na start
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                AppOpenAdManager.shared.showAdIfAvailable() // Wyświetl po powrocie do apki
            }
        }
    }
}
