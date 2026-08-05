import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var trackingNumber = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Śledzenie przesyłek")) {
                    TextField("Wprowadź numer listu przewozowego", text: $trackingNumber)
                    Button(action: {
                        // Akcja wyszukiwania
                    }) {
                        Text("Szukaj")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                Section(header: Text("Aktywne zlecenia logistyczne")) {
                    Text("Brak aktywnych tras")
                        .foregroundColor(.gray)
                        .italic()
                }
            }
            .navigationTitle("Moje Zlecenia")
        }
    }
}
