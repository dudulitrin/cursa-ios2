import SwiftUI
import ReplayKit

@main
struct CursaApp: App {
    var body: some Scene { WindowGroup { MainView() } }
}

struct MainView: View {
    @StateObject private var model = PiPModel()
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("cursa.").font(.largeTitle.bold())
                Text("Lei/km, direct peste cursă").font(.title2.bold())
                Text("PROTOTIP · PORNIRE SIMPLĂ v2").font(.caption).foregroundStyle(.secondary)
                PreviewView(model: model).frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 20))
                Text(model.status).font(.callout)
                HStack(spacing: 14) {
                    BroadcastPicker().frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("1. Pornește").font(.headline)
                        Text("Apasă cercul albastru din stânga.").font(.subheadline)
                    }
                }
                Text("2. În fereastra iOS, selectează Cursa Capture și confirmă «Pornește difuzarea». Lasă microfonul oprit.")
                Button("3. Activează panoul PiP") { model.demo = false; model.render(); model.start() }.buttonStyle(.borderedProminent)
                Text("Acum deschide Bolt Driver. Ține panoul sus, deasupra ofertei. Când primim o ofertă recunoscută, afișăm lei/km.")
                Button("Oprește PiP") { model.stop() }
                Text("Oprește separat captura din indicatorul de înregistrare iOS. Imaginile sunt analizate local; nu sunt salvate sau trimise pe internet. Sunt partajate local numai prețul, distanțele și momentul citirii.").font(.footnote).foregroundStyle(.secondary)
                DisclosureGroup("Diagnostic și test separat") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(SharedStore.diagnostic).font(.caption).textSelection(.enabled)
                        Text(BroadcastPicker.extensionDescription).font(.caption).textSelection(.enabled)
                        Button("Test PiP — date demonstrative") { model.demo = true; model.render(); model.start() }
                        Button("Revino la citirea reală") { model.demo = false; model.render() }
                        Text("Testul demo nu confirmă citirea Bolt. Verifică funcționarea când ești staționat.").font(.footnote)
                    }
                }
            }.padding(24)
        }.onAppear { model.demo = false; model.setup(); model.render() }
    }
}

struct BroadcastPicker: UIViewRepresentable {
    static var extensionBundle: Bundle? {
        guard let plugins = Bundle.main.builtInPlugInsURL,
              let contents = try? FileManager.default.contentsOfDirectory(at: plugins, includingPropertiesForKeys: nil) else { return nil }
        return contents.compactMap { Bundle(url: $0) }.first {
            ($0.infoDictionary?["NSExtension"] as? [String: Any])?["NSExtensionPointIdentifier"] as? String == "com.apple.broadcast-services-upload"
        }
    }
    static var extensionDescription: String {
        "Extensie inclusă: \(extensionBundle?.bundleIdentifier ?? "NU — extensia lipsește din instalare")"
    }
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        if let extensionBundle = Self.extensionBundle {
            view.preferredExtension = extensionBundle.bundleIdentifier
        }
        view.tintColor = .systemBlue
        for button in view.subviews.compactMap({ $0 as? UIButton }) {
            button.tintColor = .systemBlue
            button.accessibilityLabel = "Pornește difuzarea Cursa"
        }
        view.showsMicrophoneButton = false
        return view
    }
    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}

struct PreviewView: UIViewRepresentable {
    let model: PiPModel
    func makeUIView(context: Context) -> VideoView { model.view }
    func updateUIView(_ uiView: VideoView, context: Context) {}
}
