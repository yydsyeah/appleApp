import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "iphone")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Hello, IPA!")
                .font(.largeTitle.bold())

            Text("Built by Codex")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
