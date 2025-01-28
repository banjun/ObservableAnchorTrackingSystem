import SwiftUI

#if DEBUG
import SwiftHotReload
extension App {
    static let reloader = ProxyReloader.init(.init(targetSwiftFile: URL(filePath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("_RuntimeOverrides.swift")))
}
#endif

@main
struct App: SwiftUI.App {
    @State private var immersionStyle: ImmersionStyle = .progressive(0...1, initialAmount: 1)
    @State private var player: AnchorPlayer = .init()
    @State private var model: Model = .init()
    @MainActor @Observable final class Model {
        var upperLimbVisibility: Visibility = .visible
    }

    var body: some Scene {
        WindowGroup(id: "c") {
            ControlPanel()
                .environment(player)
                .environment(model)
                .onAppear {_ = App.reloader}
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.automatic)

        ImmersiveSpace(id: "i") {
            ImmersiveView()
                .environment(model)
                .environment(player)
        }
        .immersionStyle(selection: $immersionStyle, in: .progressive, .mixed)
     }
}

