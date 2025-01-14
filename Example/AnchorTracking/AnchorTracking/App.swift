import SwiftUI

@main
struct App: SwiftUI.App {
    @State private var immersionStyle: ImmersionStyle = .progressive(0...1, initialAmount: 1)
    @State private var player: AnchorPlayer = .init()

    var body: some Scene {
        WindowGroup(id: "c") {
            ControlPanel()
                .environment(player)
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

