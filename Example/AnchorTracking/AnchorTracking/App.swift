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

    var body: some Scene {
        WindowGroup(id: "c") {
            ControlPanel()
                .environment(player)
                .onAppear {_ = App.reloader}
        }
        .windowResizability(.contentMinSize)
        .windowStyle(.automatic)

        ImmersiveSpace(id: "i") {
            ImmersiveView()
                .environment(player)
        }
        .immersionStyle(selection: $immersionStyle, in: .progressive, .mixed)
     }
}

