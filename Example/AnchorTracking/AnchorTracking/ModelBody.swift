import SwiftUI
import RealityKit
import Observation
import ARKit

@MainActor @Observable final class ModelBody {
    let root: Entity = .init()
    let origin: Entity = .init(axesWithLength: 0.1)
    let anchorEntities: [AnchoringComponent.Target: Entity]
    @ObservationIgnored var transform: Transform = .init(translation: .init(0, 0, -1)) {
        didSet {root.transform = transform}
    }

    private let robotRotation: simd_quatf = .init(from: .init(0, 0, 1), to: .init(0, 0, -1)) // .init(.identity)
    private var skelEntity: ModelEntity?
    private var skelBindTransforms: [String: Transform] = [:]
    
    init(anchorTargets: [AnchoringComponent.Target], showsSkeleton: Bool = false) {
        root.transform = transform
        origin.components.set(CollisionComponent(shapes: [.generateSphere(radius: Float(0.1 / 2))], isStatic: true))
        origin.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        root.addChild(origin)

        anchorEntities = anchorTargets.reduce(into: [:]) {
            $0[$1] = .init(axesWithLength: 0.02);
            $0[$1]?.isEnabled = false
        }
        anchorEntities.forEach {root.addChild($1)}

        Task {
            guard let robot = try? await Entity(named: "robot", in: nil) else {
                NSLog("%@", "NOTE: To use robot.usdz, read robot.md")
                return
            }
            robot.transform.rotation = robotRotation
            root.addChild(robot)

            let skelEntity = robot.findSkeltalPosesEntity()!
            self.skelEntity = skelEntity
            let skeleton = skelEntity.model!.mesh.contents.skeletons.first!

            if showsSkeleton {
                addSkeletonVisualization(robot: robot, skeleton: skeleton)
            }

            var rig = try! IKRig(for: skeleton)
            rig.maxIterations = 30
            rig.globalFkWeight = 0.02
            let joints: [String: String] = skeleton.joints.reduce(into: [:]) {
                $0[$1.name.components(separatedBy: "/").last!] = $1.name
            }
            skelBindTransforms = joints.reduce(into: [:]) {
                let (label, id) = $1
                $0[label] = skeleton.joints.first {$0.name == id}.map {Transform(matrix: Transform(scale: .init(repeating: 0.01)).matrix *  $0.inverseBindPoseMatrix.inverse)}
            }
            rig.constraints = [
                .parent(named: "head", on: joints["head"]!, positionWeight: .init(11, 11, 11), orientationWeight: .init(repeating: 120)),
                .parent(named: "neck", on: joints["neck"]!),
                .parent(named: "L_wrist", on: joints["L_wrist"]!, positionWeight: .init(200, 200, 200), orientationWeight: .init(repeating: 120)),
                .parent(named: "R_wrist", on: joints["R_wrist"]!, positionWeight: .init(200, 200, 200), orientationWeight: .init(repeating: 120)),
                .parent(named: "L_thumbEnd", on: joints["L_thumbEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "R_thumbEnd", on: joints["R_thumbEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "L_indexEnd", on: joints["L_indexEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "R_indexEnd", on: joints["R_indexEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "L_middleEnd", on: joints["L_middleEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "R_middleEnd", on: joints["R_middleEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "L_pinkyEnd", on: joints["L_pinkyEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "R_pinkyEnd", on: joints["R_pinkyEnd"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 300)),
                .parent(named: "L_toe", on: joints["L_toe"]!, positionWeight: .init(0, 300, 0), orientationWeight: .init(repeating: 11)),
                .parent(named: "R_toe", on: joints["R_toe"]!, positionWeight: .init(0, 300, 0), orientationWeight: .init(repeating: 11)),
            ]
            rig.joints[joints["spine01"]!]!.limits = .init(minimumAngles: .init(0.1, 0.1, 0.1) * -.pi,
                                                           maximumAngles: .init(0.1, 0.1, 0.1) * .pi)
            rig.joints[joints["spine02"]!]!.limits = .init(minimumAngles: .init(0.1, 0.1, 0.1) * -.pi,
                                                           maximumAngles: .init(0.1, 0.1, 0.1) * .pi)
            rig.joints[joints["chest"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                           maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["L_arm"]!]!.limits = .init(minimumAngles: .init(0.25, 0.05, 1) * -.pi, // shoulder
                                                           maximumAngles: .init(1.00, 0.05, 0.25) * .pi)
            rig.joints[joints["L_arm1"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                            maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["L_arm2"]!]!.limits = .init(minimumAngles: .init(0.25, 0.25, 0.05) * -.pi, // elbow
                                                            maximumAngles: .init(1.00, 1.00, 0.8) * .pi)
            rig.joints[joints["L_arm3"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                            maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["L_arm4"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                            maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["R_arm"]!]!.limits = .init(minimumAngles: .init(0.25, 1, 1) * -.pi, // shoulder
                                                            maximumAngles: .init(1.00, 1, 1) * .pi)
            rig.joints[joints["R_arm1"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                             maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["R_arm2"]!]!.limits = .init(minimumAngles: .init(0.25, 0.8, 0.25) * -.pi, // elbow
                                                             maximumAngles: .init(1.00, 0.05, 1) * .pi)
            rig.joints[joints["R_arm3"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                             maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["R_arm4"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                             maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["L_wrist"]!]!.limits = .init(minimumAngles: .init(1, 1, 1) * -.pi,
                                                           maximumAngles: .init(1, 1, 1) * .pi)
            rig.joints[joints["R_wrist"]!]!.limits = .init(minimumAngles: .init(1, 1, 1) * -.pi,
                                                           maximumAngles: .init(1, 1, 1) * .pi)
            ["L_thumb01", "L_thumb02", "L_thumb03"].forEach { // rotate on +Y
                rig.joints[joints[$0]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                        maximumAngles: .init(0.05, 0.50, 0.05) * .pi)
            }
            ["L_index01", "L_index02", "L_index03", "L_middle01", "L_middle02", "L_middle03", "L_pinky01", "L_pinky02", "L_pinky03"].forEach { // rotate on -Z
                rig.joints[joints[$0]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.50) * -.pi,
                                                        maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            }
            ["R_thumb01", "R_thumb02", "R_thumb03"].forEach { // rotate on +Y
                rig.joints[joints[$0]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                        maximumAngles: .init(0.05, 0.50, 0.05) * .pi)
            }
            ["R_index01", "R_index02", "R_index03", "R_middle01", "R_middle02", "R_middle03", "R_pinky01", "R_pinky02", "R_pinky03"].forEach { // rotate on -Y
                rig.joints[joints[$0]!]!.limits = .init(minimumAngles: .init(0.05, 0.50, 0.05) * -.pi,
                                                        maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            }

            skelEntity.components.set(IKComponent(resource: try! IKResource(rig: rig)))
        }
    }

    private func addSkeletonVisualization(robot: Entity, skeleton: MeshSkeletonCollection.Element) {
        let sortGroup = ModelSortGroup(depthPass: .postPass)
        robot.recursiveModelEntities().forEach {
            $0.components.set(OpacityComponent(opacity: 0.5))
            $0.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
        }
        skeleton.joints.forEach { j in
            let e = Entity(axesWithLength: 3)
            e.transform = .init(matrix: j.inverseBindPoseMatrix.inverse)
            e.name = j.name
            e.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
            robot.addChild(e)

            if let parentIndex = j.parentIndex {
                let parentTransform = skeleton.joints[parentIndex].inverseBindPoseMatrix.inverse
                let parentTranslation = Transform(matrix: parentTransform).translation
                let vectorPtoC = e.transform.translation - parentTranslation
                let distancePtoC = length(vectorPtoC)
                let toChild = ModelEntity(mesh: .generateCone(height: distancePtoC, radius: distancePtoC / 10), materials: [UnlitMaterial(color: .cyan, applyPostProcessToneMap: false)])
                toChild.transform = Transform(matrix: Transform(rotation: .init(from: .init(0, 1, 0), to: normalize(vectorPtoC)), translation: parentTranslation).matrix * Transform(translation: .init(0, distancePtoC / 2, 0)).matrix)
                toChild.components.set(OpacityComponent(opacity: 0.5))
                toChild.components.set(ModelSortGroupComponent(group: sortGroup, order: 0))
                robot.addChild(toChild)
            }
        }
    }

    func setTransforms(transforms: [AnchoringComponent.Target: Transform]) {
        anchorEntities.forEach {$1.isEnabled = false}
        transforms.forEach { target, transform in
            anchorEntities[target]?.transform = transform
            anchorEntities[target]?.isEnabled = true
            anchorEntities[target]?.components.set(OpacityComponent(opacity: 0.2))
        }

        applyToRobotIK(transforms: transforms)
    }

    private func applyToRobotIK(transforms: [AnchoringComponent.Target: Transform]) {
        guard let skelEntity, let ik = skelEntity.components[IKComponent.self] else { return }
        guard let solver = ik.solvers.first else { return }

        let leftHandRotation = simd_quatf(angle: -.pi / 4, axis: .init(0, 1, 0))
        let rightHandRotation = simd_quatf(angle: -.pi / 4, axis: .init(1, 0, 0))
        func target(transform t: Transform, additionalRotation r: simd_quatf) -> Transform {
            Transform(matrix: skelEntity.convert(transform: t, from: root).matrix * Transform(rotation: r).matrix)
        }
        func setTarget(constraint c: IKComponent.Constraint, transform t: Transform, additionalRotation r: simd_quatf, animationOverrideWeight: (position: Float, rotation: Float) = (1, 1)) {
            c.target = target(transform: t, additionalRotation: r)
            c.animationOverrideWeight = animationOverrideWeight
        }

        if let c = solver.constraints["head"], let t = transforms[.head], let bindTransform = skelBindTransforms["head"] {
            setTarget(constraint: c, transform: t, additionalRotation: robotRotation * bindTransform.rotation)
        }
        if let c = solver.constraints["L_wrist"], let t = transforms[.hand(.left, location: .wrist)] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["R_wrist"], let t = transforms[.hand(.right, location: .wrist)] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["L_thumbEnd"], let t = transforms[.hand(.left, location: .thumbTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["R_thumbEnd"], let t = transforms[.hand(.right, location: .thumbTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["L_indexEnd"], let t = transforms[.hand(.left, location: .indexFingerTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["R_indexEnd"], let t = transforms[.hand(.right, location: .indexFingerTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["L_middleEnd"], let t = transforms[.hand(.left, location: .joint(for: .middleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["R_middleEnd"], let t = transforms[.hand(.right, location: .joint(for: .middleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["L_pinkyEnd"], let t = transforms[.hand(.left, location: .joint(for: .littleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["R_pinkyEnd"], let t = transforms[.hand(.right, location: .joint(for: .littleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["L_toe"] {
            setTarget(constraint: c, transform: .identity, additionalRotation: .init(.identity))
        }
        if let c = solver.constraints["R_toe"] {
            setTarget(constraint: c, transform: .identity, additionalRotation: .init(.identity))
        }
        skelEntity.components.set(ik)
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0).targetedToEntity(origin).onChanged { [weak self] value in
            guard let self, let rootParent = root.parent else { return }
            var location: SIMD3<Float> = value.convert(value.location3D, from: .local, to: rootParent)
            location.y = 0
            let limit: Float = 3
            location = length(location) < limit ? location : (normalize(location) * limit)
            self.transform = Transform(rotation: self.transform.rotation, translation: location)
        }
    }
}
