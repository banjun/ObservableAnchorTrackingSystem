import SwiftUI
import RealityKit
import ObservableAnchorTrackingSystem



struct ImmersiveView: View {
    @Environment(AnchorPlayer.self) private var player
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
    private let handAnchorsEntity = ObservableAnchorTrackingSystem.createAnchorTargetEntities(anchorTargets: anchorTargets, withDebugAxes: false)

    var body: some View {
        RealityView { content in
            content.add(try! await Entity(named: "SkyDome"))
            content.add(.init(axesWithLength: 0.1))
            content.add(modelBody.root)
            content.add(modelBody2.root)
            modelBody2.transform = .init(rotation: .init(angle: .pi, axis: .init(0, 1, 0)), translation: .init(1, 0, -1))
            content.add(handAnchorsEntity)
//            let skel = try! await Entity(named: "usd_skel_overview_example")
//            skel.scale = .init(repeating: 0.1)
//            skel.position = .init(0, 1, -1)
//            content.add(skel)

//            let skeletonEntity = try! await ModelEntity.createUsdSkelExample()
//            skeletonEntity.scale = .init(repeating: 0.1)
//            skeletonEntity.position = .init(0, 1, -1)
//            content.add(skeletonEntity)
//            try! await setupUsdSkelExampleIK(usdSkelExampleEntity: skeletonEntity)
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
//        .task {HandIKSystem.registerSystem()}
//        .upperLimbVisibility(.hidden)
    }
}

extension ModelEntity {
    /// create example model with skeleton: https://openusd.org/dev/api/_usd_skel__schema_overview.html
    static func createUsdSkelExample() async throws -> ModelEntity {
        var d = MeshDescriptor()
        d.positions = .init([
            .init(0.5, -0.5, 4), .init(-0.5, -0.5, 4), .init(0.5, 0.5, 4), .init(-0.5, 0.5, 4),
            .init(-0.5, -0.5, 0), .init(0.5, -0.5, 0), .init(-0.5, 0.5, 0), .init(0.5, 0.5, 0),
            .init(-0.5, 0.5, 2), .init(0.5, 0.5, 2), .init(0.5, -0.5, 2), .init(-0.5, -0.5, 2)])
        d.primitives = .trianglesAndQuads(triangles: [], quads: [
            2, 3, 1, 0,
            6, 7, 5, 4,
            8, 9, 7, 6,
            3, 2, 9, 8,
            10, 11, 4, 5,
            0, 1, 11, 10,
            7, 9, 10, 5,
            9, 2, 0, 10,
            3, 8, 11, 1,
            8, 6, 4, 11
        ])
        nonisolated(unsafe) var meshResourceContents = MeshResource.Contents()
        meshResourceContents.models = [{
            var model = try! MeshResource.Model(id: "model1", descriptors: [d])
            var part = model.parts[0]
            part.skeletonID = "skeleton1"
            part.jointInfluences = .init(influences: MeshBuffers.JointInfluences([2,2,2,2,0,0,0,0,1,1,1,1].map {.init(jointIndex: $0, weight: 1)}), influencesPerVertex: 1)
            model.parts = [part]
            return model
        }()]
        meshResourceContents.skeletons = [MeshResource.Skeleton(id: "skeleton1", joints: [
            .init(name: "Shoulder",
                  parentIndex: nil,
                  inverseBindPoseMatrix: .init([1,0,0,0], [0,1,0,0], [0,0,1,0], [0,0,0,1]).inverse,
                  restPoseTransform: .init(translation: .init(0, 0, 0))),
            .init(name: "Shoulder/Elbow",
                  parentIndex: 0,
                  inverseBindPoseMatrix:.init([1,0,0,0], [0,1,0,0], [0,0,1,0], [0,0,2,1]).inverse,
                  restPoseTransform: .init(translation: .init(0, 0, 2))),
            .init(name: "Shoulder/Elbow/Hand",
                  parentIndex: 1,
                  inverseBindPoseMatrix: .init([1,0,0,0], [0,1,0,0], [0,0,1,0], [0,0,4,1]).inverse,
                  restPoseTransform: .init(translation: .init(0, 0, 2))),
        ])]
        let r = try await MeshResource(from: meshResourceContents)
        return ModelEntity(mesh: r)
    }
}

/// usage for example:
///  ```swift
/// let skeletonEntity = try! await ModelEntity.createUsdSkelExample()
/// skeletonEntity.scale = .init(repeating: 0.1)
/// skeletonEntity.position = .init(0, 1, -1)
/// content.add(skeletonEntity)
/// try! await setupUsdSkelExampleIK(usdSkelExampleEntity: skeletonEntity)
/// ```
@MainActor
func setupUsdSkelExampleIK(usdSkelExampleEntity skeletonEntity: ModelEntity) async throws {
    NSLog("%@", "skeletalPoses = \(String(describing: skeletonEntity.components[SkeletalPosesComponent.self]))")
    NSLog("%@", "jointInfluences = \(String(describing: skeletonEntity.model!.mesh.contents.models[0].parts[0].buffers[.jointInfluences]))")
    skeletonEntity.model!.materials = [{
        var m = SimpleMaterial(color: .green, roughness: 0.7, isMetallic: false)
        m.triangleFillMode = .fill // .lines
        return m
    }()]
    let skeleton = skeletonEntity.model!.mesh.contents.skeletons.first!
    let jointNames = (shoulder: "Shoulder", elbow: "Shoulder/Elbow", hand: "Shoulder/Elbow/Hand")
    var rig = try IKRig(for: skeleton)
    rig.maxIterations = 30
    rig.globalFkWeight = 0.02
    rig.constraints = [
        .point(named: "hand", on: jointNames.hand,
               positionWeight: .init(repeating: 1)),
        .parent(named: "elbow", on: jointNames.elbow,
                positionWeight: .init(repeating: 0.05),
                orientationWeight: .init(repeating: 1)),
        .parent(named: "shoulder", on: jointNames.shoulder,
                positionWeight: .init(repeating: 0),
                orientationWeight: .init(repeating: 0.01))
    ]
    rig.joints[jointNames.elbow]!.limits = .init(
        weight: 1, boneAxis: .z,
        minimumAngles: .init(-.pi / 2, 0, -.pi / 2),
        maximumAngles: .init(0, 0, .pi / 4))
    rig.joints[jointNames.shoulder]!.limits = .init(
        weight: 1, boneAxis: .z,
        minimumAngles: .init(-.pi, -.pi / 2, 0),
        maximumAngles: .init(.pi, .pi / 4, 0))
    let resource = try IKResource(rig: rig)
    skeletonEntity.components.set(IKComponent(resource: resource))
}

@MainActor
struct HandIKSystem: System {
    static let query = EntityQuery(where: .has(IKComponent.self))
    init(scene: RealityKit.Scene) {}
    func update(context: SceneUpdateContext) {
        context.entities(matching: Self.query, updatingSystemWhen: .rendering).forEach { e in
            let ik = e.components[IKComponent.self]!
            if let hand = ik.solvers[0].constraints["hand"] {
                hand.target.translation = .init(
                    3 * Float(cos(2 * NSDate().timeIntervalSince1970)),
                    3 * Float(sin(2 * NSDate().timeIntervalSince1970)),
                    0.5)
                // NSLog("%@", "ik...target = \(hand!.target.translation)")
                hand.animationOverrideWeight.position = 1
            }
            e.components.set(ik)
        }
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveView()
}
