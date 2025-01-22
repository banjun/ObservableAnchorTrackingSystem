import Foundation
import RealityFoundation
@testable import AnchorTracking
import Spatial

extension ModelBody {
    @_dynamicReplacement(for: applyToRobotIK)
    func applyToRobotIK2(transforms: [AnchoringComponent.Target: Transform]) {
        guard let skelEntity, let ik = skelEntity.components[IKComponent.self] else { return }
        guard let solver = ik.solvers.first else { return }
        if let c = solver.constraints["head"], let t = transforms[.head], let bindTransform = skelBindTransforms["head"] {
            c.target = skelEntity.convert(transform: t, from: root) * robotRotation * bindTransform.rotation
            c.animationOverrideWeight = (1, 1)
        }
        if let c = solver.constraints["leftWrist"], let t = transforms[.hand(.left, location: .wrist)] {
            c.target = skelEntity.convert(transform: t, from: root) * .init(angle: -.pi / 4, axis: [0,1,0])
//            c.target.rotation *= .init(angle: -.pi, axis: [1,0,0])
            c.animationOverrideWeight = (1, 1)
            // NSLog("%@", "ik...target = \(c.target.translation)")
        }
        if let c = solver.constraints["rightWrist"], let t = transforms[.hand(.right, location: .wrist)] {
            c.target = skelEntity.convert(transform: t, from: root) * .init(angle: -.pi / 4, axis: [1,0,0])
            c.animationOverrideWeight = (1, 1)
            // NSLog("%@", "ik...target = \(hand!.target.translation)")
        }
        if let c = solver.constraints["leftIndexTip"], let t = transforms[.hand(.left, location: .indexFingerTip)] {
            c.target = skelEntity.convert(transform: t, from: root) * .init(angle: -.pi / 4, axis: [0,1,0])
//            c.target.rotation *= .init(angle: -.pi, axis: [1,0,0])
            c.animationOverrideWeight = (1, 1)
            // NSLog("%@", "ik...target = \(c.target.translation)")
        }
        if let c = solver.constraints["rightIndexTip"], let t = transforms[.hand(.right, location: .indexFingerTip)] {
            c.target = skelEntity.convert(transform: t, from: root) * .init(angle: -.pi / 4, axis: [1,0,0])
            c.animationOverrideWeight = (1, 1)
            // NSLog("%@", "ik...target = \(hand!.target.translation)")
        }
        if let c = solver.constraints["leftToe"] {
            c.target = .identity
            c.animationOverrideWeight = (1, 1)
        }
        if let c = solver.constraints["rightToe"] {
            c.target = .identity
            c.animationOverrideWeight = (1, 1)
        }
        skelEntity.components.set(ik)
    }
}
