import SwiftUI

@main
struct App: SwiftUI.App {
    @State private var immersionStyle: ImmersionStyle = .progressive(0...1, initialAmount: 1)

    var body: some Scene {
        WindowGroup(id: "w") {
            LandingView()
        }
        .windowStyle(.plain)

        ImmersiveSpace(id: "i") {
            ImmersiveView()
        }
        .immersionStyle(selection: $immersionStyle, in: .progressive, .mixed)
     }
}

