import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        
        // Rozwiązanie problemu nr 2: Oszukanie blokady logowania Google
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        
        // Dodatkowe parametry dla poprawnego przewijania
        webView.scrollView.bounces = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct ContentView: View {
    var body: some View {
        // Rozwiązanie problemu nr 1: Wymuszenie pełnej szerokości i wysokości
        WebView(url: URL(string: "https://my.fhi.pl")!)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}
