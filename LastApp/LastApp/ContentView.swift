import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Text("LastApp — scaffold")
            .padding()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
}
