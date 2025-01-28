import SwiftUI
import RealityKit
import ObservableAnchorTrackingSystem

struct ImmersiveView: View {
    @Environment(AnchorPlayer.self) private var player
    @Environment(App.Model.self) private var appModel
    private let modelBody: ModelBody = .init(anchorTargets: anchorTargets)
    private let modelBody2: ModelBody = .init(anchorTargets: anchorTargets)
    static let targetJoints: [AnchoringComponent.Target.HandLocation.HandJoint] = [
        .wrist,
        .thumbKnuckle,
        .thumbIntermediateBase,
        .thumbIntermediateTip,
        .thumbTip,
        .indexFingerMetacarpal,
        .indexFingerKnuckle,
        .indexFingerIntermediateBase,
        .indexFingerIntermediateTip,
        .indexFingerTip,
        .middleFingerMetacarpal,
        .middleFingerKnuckle,
        .middleFingerIntermediateBase,
        .middleFingerIntermediateTip,
        .middleFingerTip,
        .ringFingerMetacarpal,
        .ringFingerKnuckle,
        .ringFingerIntermediateBase,
        .ringFingerIntermediateTip,
        .ringFingerTip,
        .littleFingerMetacarpal,
        .littleFingerKnuckle,
        .littleFingerIntermediateBase,
        .littleFingerIntermediateTip,
        .littleFingerTip,
        .forearmWrist,
        .forearmArm,
    ]
    static let targetHandLocations: [AnchoringComponent.Target.HandLocation] = [
        .thumbTip,
        .indexFingerTip,
        .wrist,
        .palm,
        .aboveHand
    ] + targetJoints.map {.joint(for: $0)}
    static let anchorTargets: [AnchoringComponent.Target] = [.left, .right].flatMap { c in
        targetHandLocations.map {.hand(c, location: $0)}
    } + [.head]
    private let handAnchorsEntity = ObservableAnchorTrackingSystem.createAnchorTargetEntities(anchorTargets: anchorTargets, withDebugAxes: true)

    var body: some View {
        RealityView { content in
            content.add(try! await Entity(named: "SkyDome"))
            content.add(.init(axesWithLength: 0.1))
            content.add(modelBody.root)
            content.add(modelBody2.root)
            modelBody2.transform = .init(rotation: .init(angle: .pi, axis: .init(0, 1, 0)), translation: .init(1, 0, -1))
            content.add(handAnchorsEntity)
        } update: { content in
            if !player.isPlaying {
                modelBody.setTransforms(transforms: ObservableAnchorTrackingSystem.observable.transforms)
                modelBody2.setTransforms(transforms: ObservableAnchorTrackingSystem.observable.transforms)
            } else {
                modelBody.setTransforms(transforms: player.transforms)
                modelBody2.setTransforms(transforms: player.transforms)
            }
        }
        .simultaneousGesture(modelBody.dragGesture)
        .simultaneousGesture(modelBody2.dragGesture)
        .task {ObservableAnchorTrackingSystem.registerSystem()}
        .upperLimbVisibility(appModel.upperLimbVisibility)
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
