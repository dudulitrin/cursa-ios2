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
                Text("PROTOTIP EXPERIMENTAL · iOS 26").font(.caption).foregroundStyle(.secondary)
                PreviewView(model: model).frame(height: 180).clipShape(RoundedRectangle(cornerRadius: 20))
                Text(model.status).font(.callout)
                DisclosureGroup("Diagnostic instalare") {
                    Text(SharedStore.diagnostic).font(.caption).textSelection(.enabled)
                }
                Button("1. Test PiP cu 3,32 lei/km") { model.demo = true; model.render(); model.start() }.buttonStyle(.borderedProminent)
                Button("2. Activează citirea reală") { model.demo = false; model.render() }.buttonStyle(.bordered)
                Text("3. Apasă butonul de mai jos și pornește difuzarea Cursa. Microfonul nu este necesar.")
                BroadcastPicker().frame(width: 64, height: 64)
                Button("4. Deschide fereastra PiP") { model.start() }.buttonStyle(.borderedProminent)
                Text("Apoi deschide manual Bolt Driver. Mută PiP în partea de sus, fără să acoperi oferta. Verifică prototipul când ești staționat.")
                Button("Oprește PiP") { model.stop() }
                Text("Oprește separat captura din indicatorul de înregistrare iOS. Imaginile sunt analizate local; nu sunt salvate sau trimise pe internet. Sunt partajate local numai prețul, distanțele și momentul citirii.").font(.footnote).foregroundStyle(.secondary)
                Text("Instalarea gratuită poate elimina App Groups. În acest caz funcționează doar testul PiP, iar citirea live raportează explicit problema.").font(.footnote).foregroundStyle(.orange)
            }.padding(24)
        }.onAppear { model.setup() }
    }
}

struct BroadcastPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
        if let plugins = Bundle.main.builtInPlugInsURL,
           let contents = try? FileManager.default.contentsOfDirectory(at: plugins, includingPropertiesForKeys: nil),
           let extensionBundle = contents.compactMap({ Bundle(url: $0) }).first(where: {
               ($0.infoDictionary?["NSExtension"] as? [String: Any])?["NSExtensionPointIdentifier"] as? String == "com.apple.broadcast-services-upload"
           }) {
            view.preferredExtension = extensionBundle.bundleIdentifier
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
