import SwiftUI
import RealityKit
import ObservableAnchorTrackingSystem

struct ImmersiveView: View {
    private let modelBody: ModelBody = .init(anchorTargets: anchorTargets)
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
    private let handAnchorsEntity = ObservableAnchorTrackingSystem.createAnchorTargetEntities(anchorTargets: anchorTargets, withDebugAxes: false)

    var body: some View {
        RealityView { content in
            content.add(try! await Entity(named: "SkyDome"))
            content.add(.init(axesWithLength: 0.1))
            content.add(modelBody.root)
            content.add(handAnchorsEntity)
        } update: { content in
            modelBody.setTransforms(transforms: ObservableAnchorTrackingSystem.observable.transforms)
        }
        .simultaneousGesture(modelBody.dragGesture)
        .task {ObservableAnchorTrackingSystem.registerSystem()}
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
