import SwiftUI

struct LandingView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ProgressView().task {
            try! await Task.sleep(for: .seconds(0.5))
            await openImmersiveSpace(id: "i")
            dismiss()
        }
    }
}
