import SwiftUI
import RealityKit
import Observation
import ARKit
import GoncharKit

@MainActor @Observable final class ModelBody {
    let root: Entity = .init()
    let origin: Entity = .init(axesWithLength: 0.1)
    let anchorEntities: [AnchoringComponent.Target: Entity]
    @ObservationIgnored var transform: Transform = .init(translation: .init(0, 0, -1)) {
        didSet {root.transform = transform}
    }

    private let robotRotation: simd_quatf = .init(from: .init(0, 0, 1), to: .init(0, 0, -1))
    private var skelEntity: ModelEntity?
    private var skelBindTransforms: [String: Transform] = [:]

    init(anchorTargets: [AnchoringComponent.Target]) {
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
            let robot = try! await Entity(named: "robot", in: nil)
            robot.transform.rotation = robotRotation
            root.addChild(robot)
//            robot.visualizeBones(size: 5)

            let skelEntity = robot.findSkeltalPosesEntity()!
            self.skelEntity = skelEntity
            let skeleton = skelEntity.model!.mesh.contents.skeletons.first!
            var rig = try! IKRig(for: skeleton)
            rig.maxIterations = 30
            rig.globalFkWeight = 0.02
            let joints: [String: String] = [
                "hips":              "root/hips",
                "spine01":          "root/hips/spine01",
                "spine02":          "root/hips/spine01/spine02",
                "chest":            "root/hips/spine01/spine02/chest",
                "backpack":         "root/hips/spine01/spine02/chest/backpack",
                "neck":             "root/hips/spine01/spine02/chest/neck",
                "head":             "root/hips/spine01/spine02/chest/neck/head",
                "leftArm":          "root/hips/spine01/spine02/chest/L_clavicle/L_arm",
                "leftArm1":         "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1",
                "leftArm2":         "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2",
                "leftArm3":         "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2/L_arm3",
                "leftArm4":         "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2/L_arm3/L_arm4",
                "leftWrist":        "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2/L_arm3/L_arm4/L_wrist",
                "leftThumbTip":     "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2/L_arm3/L_arm4/L_wrist/L_thumb01/L_thumb02/L_thumb03/L_thumbEnd",
                "leftIndexTip":     "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2/L_arm3/L_arm4/L_wrist/L_index01/L_index02/L_index03/L_indexEnd",
                "leftMiddleTip":    "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2/L_arm3/L_arm4/L_wrist/L_middle01/L_middle02/L_middle03/L_middleEnd",
                "leftPinkyTip":     "root/hips/spine01/spine02/chest/L_clavicle/L_arm/L_arm1/L_arm2/L_arm3/L_arm4/L_wrist/L_pinky01/L_pinky02/L_pinky03/L_pinkyEnd",
                "rightArm":         "root/hips/spine01/spine02/chest/R_clavicle/R_arm",
                "rightArm1":        "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1",
                "rightArm2":        "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2",
                "rightArm3":        "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2/R_arm3",
                "rightArm4":        "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2/R_arm3/R_arm4",
                "rightWrist":       "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2/R_arm3/R_arm4/R_wrist",
                "rightThumbTip":    "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2/R_arm3/R_arm4/R_wrist/R_thumb01/R_thumb02/R_thumb03/R_thumbEnd",
                "rightIndexTip":    "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2/R_arm3/R_arm4/R_wrist/R_index01/R_index02/R_index03/R_indexEnd",
                "rightMiddleTip":   "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2/R_arm3/R_arm4/R_wrist/R_middle01/R_middle02/R_middle03/R_middleEnd",
                "rightPinkyTip":    "root/hips/spine01/spine02/chest/R_clavicle/R_arm/R_arm1/R_arm2/R_arm3/R_arm4/R_wrist/R_pinky01/R_pinky02/R_pinky03/R_pinkyEnd",
                "leftFemur":        "root/hips/hips_sway/L_femur_IK",
                "leftToe":          "root/hips/hips_sway/L_femur_IK/L_knee_IK/L_ankle_IK/L_ball_IK/L_toe_IK",
                "rightFemur":       "root/hips/hips_sway/R_femur_IK",
                "rightToe":         "root/hips/hips_sway/R_femur_IK/R_knee_IK/R_ankle_IK/R_ball_IK/R_toe_IK",
            ]
            skelBindTransforms = joints.reduce(into: [:]) {
                let (label, id) = $1
                $0[label] = skeleton.joints.first {$0.name == id}.map {Transform(matrix: $0.inverseBindPoseMatrix.inverse)}
            }
            rig.constraints = [
                .parent(named: "head", on: joints["head"]!, positionWeight: .init(11, 11, 11), orientationWeight: .init(repeating: 120)),
                .parent(named: "neck", on: joints["neck"]!),
                .parent(named: "leftWrist", on: joints["leftWrist"]!, positionWeight: .init(200, 200, 200), orientationWeight: .init(repeating: 120)),
                .parent(named: "rightWrist", on: joints["rightWrist"]!, positionWeight: .init(200, 200, 200), orientationWeight: .init(repeating: 120)),
                .parent(named: "leftThumbTip", on: joints["leftThumbTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "rightThumbTip", on: joints["rightThumbTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "leftIndexTip", on: joints["leftIndexTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "rightIndexTip", on: joints["rightIndexTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "leftMiddleTip", on: joints["leftMiddleTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "rightMiddleTip", on: joints["rightMiddleTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "leftPinkyTip", on: joints["leftPinkyTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "rightPinkyTip", on: joints["rightPinkyTip"]!, positionWeight: .init(repeating: 50), orientationWeight: .init(repeating: 120)),
                .parent(named: "leftToe", on: joints["leftToe"]!, positionWeight: .init(0, 300, 0), orientationWeight: .init(repeating: 11)),
                .parent(named: "rightToe", on: joints["rightToe"]!, positionWeight: .init(0, 300, 0), orientationWeight: .init(repeating: 11)),
            ]
            rig.joints[joints["spine01"]!]!.limits = .init(minimumAngles: .init(0.1, 0.1, 0.1) * -.pi,
                                                           maximumAngles: .init(0.1, 0.1, 0.1) * .pi)
            rig.joints[joints["spine02"]!]!.limits = .init(minimumAngles: .init(0.1, 0.1, 0.1) * -.pi,
                                                           maximumAngles: .init(0.1, 0.1, 0.1) * .pi)
            rig.joints[joints["chest"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                           maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["chest"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                           maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["leftArm"]!]!.limits = .init(minimumAngles: .init(0.25, 0.05, 1) * -.pi, // shoulder
                                                           maximumAngles: .init(1.00, 0.05, 0.25) * .pi)
            rig.joints[joints["leftArm1"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                            maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["leftArm2"]!]!.limits = .init(minimumAngles: .init(0.25, 0.25, 0.05) * -.pi, // elbow
                                                            maximumAngles: .init(1.00, 1.00, 0.8) * .pi)
            rig.joints[joints["leftArm3"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                            maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["leftArm4"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                            maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["rightArm"]!]!.limits = .init(minimumAngles: .init(0.25, 1, 0.05) * -.pi, // shoulder
                                                            maximumAngles: .init(1.00, 0.25, 0.05) * .pi)
            rig.joints[joints["rightArm1"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                             maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["rightArm2"]!]!.limits = .init(minimumAngles: .init(0.25, 0.8, 0.25) * -.pi, // elbow
                                                             maximumAngles: .init(1.00, 0.05, 1) * .pi)
            rig.joints[joints["rightArm3"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                             maximumAngles: .init(0.05, 0.05, 0.05) * .pi)
            rig.joints[joints["rightArm4"]!]!.limits = .init(minimumAngles: .init(0.05, 0.05, 0.05) * -.pi,
                                                             maximumAngles: .init(0.05, 0.05, 0.05) * .pi)

            skelEntity.components.set(IKComponent(resource: try! IKResource(rig: rig)))

            // RobotIKSystem.registerSystem()
        }
    }

    func setTransforms(transforms: [AnchoringComponent.Target: Transform]) {
        anchorEntities.forEach {$1.isEnabled = false}
        transforms.forEach { target, transform in
            anchorEntities[target]?.transform = transform
//            anchorEntities[target]?.isEnabled = true
//            anchorEntities[target]?.components.set(OpacityComponent(opacity: 0.2))
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
        func setTarget(constraint c: IKComponent.Constraint, transform t: Transform, additionalRotation r: simd_quatf, animationOverrideWeight: (position: Float, rotation: Float) = (1, 1_)) {
            c.target = target(transform: t, additionalRotation: r)
            c.animationOverrideWeight = animationOverrideWeight
        }

        if let c = solver.constraints["head"], let t = transforms[.head], let bindTransform = skelBindTransforms["head"] {
            setTarget(constraint: c, transform: t, additionalRotation: robotRotation * bindTransform.rotation)
        }
        if let c = solver.constraints["leftWrist"], let t = transforms[.hand(.left, location: .wrist)] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["rightWrist"], let t = transforms[.hand(.right, location: .wrist)] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["leftThumbTip"], let t = transforms[.hand(.left, location: .thumbTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["rightThumbTip"], let t = transforms[.hand(.right, location: .thumbTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["leftIndexTip"], let t = transforms[.hand(.left, location: .indexFingerTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["rightIndexTip"], let t = transforms[.hand(.right, location: .indexFingerTip)] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["leftMiddleTip"], let t = transforms[.hand(.left, location: .joint(for: .middleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["rightMiddleTip"], let t = transforms[.hand(.right, location: .joint(for: .middleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["leftPinkyTip"], let t = transforms[.hand(.left, location: .joint(for: .littleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: leftHandRotation)
        }
        if let c = solver.constraints["rightPinkyTip"], let t = transforms[.hand(.right, location: .joint(for: .littleFingerTip))] {
            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
        }
        if let c = solver.constraints["leftToe"] {
            setTarget(constraint: c, transform: .identity, additionalRotation: .init(.identity))
        }
        if let c = solver.constraints["rightToe"] {
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
            let rotation: simd_quatf = .init(.identity)
            self.transform = Transform(rotation: self.transform.rotation, translation: location)
        }
    }
}
