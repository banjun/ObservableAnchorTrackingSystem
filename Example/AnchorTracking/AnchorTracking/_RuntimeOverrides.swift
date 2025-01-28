import Foundation
import RealityFoundation
@testable import AnchorTracking
import Spatial

extension ModelBody {
    @_dynamicReplacement(for: applyToRobotIK)
    func applyToRobotIK2(transforms: [AnchoringComponent.Target: Transform]) {
        guard let skelEntity, let ik = skelEntity.components[IKComponent.self] else { return }
        guard let solver = ik.solvers.first else { return }

        let leftHandRotation = simd_quatf(angle: .pi / 4, axis: .init(0, 0.25, 1))
        let rightHandRotation = simd_quatf(angle: 0 * -.pi / 4, axis: .init(1, 0, 0))
        func target(transform t: Transform, additionalRotation r: simd_quatf) -> Transform {
            Transform(matrix: skelEntity.convert(transform: t, from: root).matrix * Transform(rotation: r).matrix)
        }
        func setTarget(constraint c: IKComponent.Constraint, transform t: Transform, additionalRotation r: simd_quatf, animationOverrideWeight: (position: Float, rotation: Float) = (1, 1_)) {
            c.target = target(transform: t, additionalRotation: r)
            c.animationOverrideWeight = animationOverrideWeight
        }

        let lWristBindTransform = skelBindTransforms["L_wrist"]
        let lWristTransform = transforms[.hand(.left, location: .thumbTip)].map {
            var t = $0
            t.rotation = .init(angle: -.pi / 4, axis: .init(0, 1, 0)) * t.rotation
            return t
        }
        let handScale: Float = 1

        if let c = solver.constraints["head"], let t = transforms[.head], let bindTransform = skelBindTransforms["head"] {
            setTarget(constraint: c, transform: t, additionalRotation: robotRotation * bindTransform.rotation)
        }
        if let c = solver.constraints["L_wrist"], let t = transforms[.hand(.left, location: .wrist)], let bindTransform = skelBindTransforms["L_wrist"] {
            var t = Transform(matrix: Transform(rotation: .init(angle: .pi, axis: .init(0,1,0))).matrix * t.matrix)
            setTarget(constraint: c, transform: t, additionalRotation: robotRotation)
            c.offset.rotation = t.rotation
        }
        if let c = solver.constraints["R_wrist"], let t = transforms[.hand(.right, location: .wrist)] {
            setTarget(constraint: c, transform: t, additionalRotation: simd_quatf(angle: .pi, axis: .init(1, 0, 0)))
        }
        skelEntity.components.set(ik)
        return
//        if let c = solver.constraints["L_thumbEnd"], let t = transforms[.hand(.left, location: .thumbTip)], let bindTransform = skelBindTransforms["L_thumbEnd"] {
//            var t2 = bindTransform
//            setTarget(constraint: c, transform: t2, additionalRotation: robotRotation)
//        }
//        if let c = solver.constraints["R_thumbEnd"], let t = transforms[.hand(.right, location: .thumbTip)] {
//            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
//        }
//        if let c = solver.constraints["L_indexEnd"], let t = transforms[.hand(.left, location: .indexFingerTip)], let bindTransform = skelBindTransforms["L_indexEnd"] {
//            var t2 = bindTransform
//            setTarget(constraint: c, transform: t2, additionalRotation: robotRotation)
//        }
//        if let c = solver.constraints["R_indexEnd"], let t = transforms[.hand(.right, location: .indexFingerTip)] {
//            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
//        }
//        if let c = solver.constraints["L_middleEnd"], let t = transforms[.hand(.left, location: .joint(for: .middleFingerTip))], let bindTransform = skelBindTransforms["L_middleEnd"] {
//            var t2 = bindTransform
//            setTarget(constraint: c, transform: t2, additionalRotation: robotRotation)
//        }
//        if let c = solver.constraints["R_middleEnd"], let t = transforms[.hand(.right, location: .joint(for: .middleFingerTip))] {
//            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
//        }
//        if let c = solver.constraints["L_pinkyEnd"], let t = transforms[.hand(.left, location: .joint(for: .littleFingerTip))], let bindTransform = skelBindTransforms["L_pinkyEnd"] {
//            var t2 = bindTransform
//            setTarget(constraint: c, transform: t2, additionalRotation: robotRotation)
//        }
//        if let c = solver.constraints["R_pinkyEnd"], let t = transforms[.hand(.right, location: .joint(for: .littleFingerTip))] {
//            setTarget(constraint: c, transform: t, additionalRotation: rightHandRotation)
//        }
//        if let c = solver.constraints["L_toe"] {
//            setTarget(constraint: c, transform: .identity, additionalRotation: .init(Rotation3D.identity))
//        }
//        if let c = solver.constraints["R_toe"] {
//            setTarget(constraint: c, transform: .identity, additionalRotation: .init(Rotation3D.identity))
//        }
//        skelEntity.components.set(ik)
    }
}
