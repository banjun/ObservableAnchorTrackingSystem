import Foundation
import RealityKit

struct AnchorSession: Codable {
    var start: Date
    var frames: [Frame] = []
    var duration: TimeInterval { frames.last?.time ?? 0 }
    struct Frame: Codable {
        /// relative to the start
        var time: TimeInterval
        var transforms: [Target: Transform]
    }
    enum Target: String, Codable {
        case hand_left_thumbTip
        case hand_left_indexFingerTip
        case hand_left_wrist
        case hand_left_palm
        case hand_left_aboveHand
        case hand_left_joint_for_wrist
        case hand_left_joint_for_thumbKnuckle
        case hand_left_joint_for_thumbIntermediateBase
        case hand_left_joint_for_thumbIntermediateTip
        case hand_left_joint_for_thumbTip
        case hand_left_joint_for_indexFingerMetacarpal
        case hand_left_joint_for_indexFingerKnuckle
        case hand_left_joint_for_indexFingerIntermediateBase
        case hand_left_joint_for_indexFingerIntermediateTip
        case hand_left_joint_for_indexFingerTip
        case hand_left_joint_for_middleFingerMetacarpal
        case hand_left_joint_for_middleFingerKnuckle
        case hand_left_joint_for_middleFingerIntermediateBase
        case hand_left_joint_for_middleFingerIntermediateTip
        case hand_left_joint_for_middleFingerTip
        case hand_left_joint_for_ringFingerMetacarpal
        case hand_left_joint_for_ringFingerKnuckle
        case hand_left_joint_for_ringFingerIntermediateBase
        case hand_left_joint_for_ringFingerIntermediateTip
        case hand_left_joint_for_ringFingerTip
        case hand_left_joint_for_littleFingerMetacarpal
        case hand_left_joint_for_littleFingerKnuckle
        case hand_left_joint_for_littleFingerIntermediateBase
        case hand_left_joint_for_littleFingerIntermediateTip
        case hand_left_joint_for_littleFingerTip
        case hand_left_joint_for_forearmWrist
        case hand_left_joint_for_forearmArm
        case hand_right_thumbTip
        case hand_right_indexFingerTip
        case hand_right_wrist
        case hand_right_palm
        case hand_right_aboveHand
        case hand_right_joint_for_wrist
        case hand_right_joint_for_thumbKnuckle
        case hand_right_joint_for_thumbIntermediateBase
        case hand_right_joint_for_thumbIntermediateTip
        case hand_right_joint_for_thumbTip
        case hand_right_joint_for_indexFingerMetacarpal
        case hand_right_joint_for_indexFingerKnuckle
        case hand_right_joint_for_indexFingerIntermediateBase
        case hand_right_joint_for_indexFingerIntermediateTip
        case hand_right_joint_for_indexFingerTip
        case hand_right_joint_for_middleFingerMetacarpal
        case hand_right_joint_for_middleFingerKnuckle
        case hand_right_joint_for_middleFingerIntermediateBase
        case hand_right_joint_for_middleFingerIntermediateTip
        case hand_right_joint_for_middleFingerTip
        case hand_right_joint_for_ringFingerMetacarpal
        case hand_right_joint_for_ringFingerKnuckle
        case hand_right_joint_for_ringFingerIntermediateBase
        case hand_right_joint_for_ringFingerIntermediateTip
        case hand_right_joint_for_ringFingerTip
        case hand_right_joint_for_littleFingerMetacarpal
        case hand_right_joint_for_littleFingerKnuckle
        case hand_right_joint_for_littleFingerIntermediateBase
        case hand_right_joint_for_littleFingerIntermediateTip
        case hand_right_joint_for_littleFingerTip
        case hand_right_joint_for_forearmWrist
        case hand_right_joint_for_forearmArm
        case head
    }
}

extension [AnchorSession.Target: Transform] {
    init(_ transforms: [AnchoringComponent.Target: Transform]) {
        self = transforms.reduce(into: [:]) {
            do {
                $0[try .init($1.key)] = $1.value
            } catch {
                NSLog("%@", "ignorable error at \(#function): target = \($1.key)")
            }
        }
    }
}

extension [AnchoringComponent.Target: Transform] {
    init(_ transforms: [AnchorSession.Target: Transform]) {
        self = transforms.reduce(into: [:]) {
            $0[.init($1.key)] = $1.value
        }
    }
}

extension AnchorSession.Target {
    enum AnchoringComponentError: Error {
        case unsupported(String)
        init(_ target: AnchoringComponent.Target) {
            self = .unsupported(String(describing: target))
        }
    }

    init(_ target: AnchoringComponent.Target) throws {
        switch target {
        case let .hand(c, location: l):
            let chirality: String = switch c {
            case .left: "left"
            case .right: "right"
            case .either: throw AnchoringComponentError(target)
            @unknown default: throw AnchoringComponentError(target)
            }

            let location: String = switch l {
            case .thumbTip: "thumbTip"
            case .indexFingerTip: "indexFingerTip"
            case .wrist: "wrist"
            case .palm: "palm"
            case .aboveHand: "aboveHand"
            case .joint(for: .wrist): "joint_for_wrist"
            case .joint(for: .thumbKnuckle): "joint_for_thumbKnuckle"
            case .joint(for: .thumbIntermediateBase): "joint_for_thumbIntermediateBase"
            case .joint(for: .thumbIntermediateTip): "joint_for_thumbIntermediateTip"
            case .joint(for: .thumbTip): "joint_for_thumbTip"
            case .joint(for: .indexFingerMetacarpal): "joint_for_indexFingerMetacarpal"
            case .joint(for: .indexFingerKnuckle): "joint_for_indexFingerKnuckle"
            case .joint(for: .indexFingerIntermediateBase): "joint_for_indexFingerIntermediateBase"
            case .joint(for: .indexFingerIntermediateTip): "joint_for_indexFingerIntermediateTip"
            case .joint(for: .indexFingerTip): "joint_for_indexFingerTip"
            case .joint(for: .middleFingerMetacarpal): "joint_for_middleFingerMetacarpal"
            case .joint(for: .middleFingerKnuckle): "joint_for_middleFingerKnuckle"
            case .joint(for: .middleFingerIntermediateBase): "joint_for_middleFingerIntermediateBase"
            case .joint(for: .middleFingerIntermediateTip): "joint_for_middleFingerIntermediateTip"
            case .joint(for: .middleFingerTip): "joint_for_middleFingerTip"
            case .joint(for: .ringFingerMetacarpal): "joint_for_ringFingerMetacarpal"
            case .joint(for: .ringFingerKnuckle): "joint_for_ringFingerKnuckle"
            case .joint(for: .ringFingerIntermediateBase): "joint_for_ringFingerIntermediateBase"
            case .joint(for: .ringFingerIntermediateTip): "joint_for_ringFingerIntermediateTip"
            case .joint(for: .ringFingerTip): "joint_for_ringFingerTip"
            case .joint(for: .littleFingerMetacarpal): "joint_for_littleFingerMetacarpal"
            case .joint(for: .littleFingerKnuckle): "joint_for_littleFingerKnuckle"
            case .joint(for: .littleFingerIntermediateBase): "joint_for_littleFingerIntermediateBase"
            case .joint(for: .littleFingerIntermediateTip): "joint_for_littleFingerIntermediateTip"
            case .joint(for: .littleFingerTip): "joint_for_littleFingerTip"
            case .joint(for: .forearmWrist): "joint_for_forearmWrist"
            case .joint(for: .forearmArm): "joint_for_forearmArm"
            default: throw AnchoringComponentError(target)
            }

            guard let s = Self.init(rawValue: ["hand", chirality, location].joined(separator: "_")) else {
                throw AnchoringComponentError(target)
            }
            self = s
        case .head:
            self = .head
        case .world, .plane, .image, .referenceImage, .referenceObject: fallthrough
        @unknown default: throw AnchoringComponentError(target)
        }
    }
}

extension AnchoringComponent.Target {
    init(_ target: AnchorSession.Target) {
        self = switch target {
        case .hand_left_thumbTip: .hand(.left, location: .thumbTip)
        case .hand_left_indexFingerTip: .hand(.left, location: .indexFingerTip)
        case .hand_left_wrist: .hand(.left, location: .wrist)
        case .hand_left_palm: .hand(.left, location: .palm)
        case .hand_left_aboveHand: .hand(.left, location: .aboveHand)
        case .hand_left_joint_for_wrist: .hand(.left, location: .wrist)
        case .hand_left_joint_for_thumbKnuckle: .hand(.left, location: .joint(for: .thumbKnuckle))
        case .hand_left_joint_for_thumbIntermediateBase: .hand(.left, location: .joint(for: .thumbIntermediateBase))
        case .hand_left_joint_for_thumbIntermediateTip: .hand(.left, location: .joint(for: .thumbIntermediateTip))
        case .hand_left_joint_for_thumbTip: .hand(.left, location: .joint(for: .thumbTip))
        case .hand_left_joint_for_indexFingerMetacarpal: .hand(.left, location: .joint(for: .indexFingerMetacarpal))
        case .hand_left_joint_for_indexFingerKnuckle: .hand(.left, location: .joint(for: .indexFingerKnuckle))
        case .hand_left_joint_for_indexFingerIntermediateBase: .hand(.left, location: .joint(for: .indexFingerIntermediateBase))
        case .hand_left_joint_for_indexFingerIntermediateTip: .hand(.left, location: .joint(for: .indexFingerIntermediateTip))
        case .hand_left_joint_for_indexFingerTip: .hand(.left, location: .joint(for: .indexFingerTip))
        case .hand_left_joint_for_middleFingerMetacarpal: .hand(.left, location: .joint(for: .middleFingerMetacarpal))
        case .hand_left_joint_for_middleFingerKnuckle: .hand(.left, location: .joint(for: .middleFingerKnuckle))
        case .hand_left_joint_for_middleFingerIntermediateBase: .hand(.left, location: .joint(for: .middleFingerIntermediateBase))
        case .hand_left_joint_for_middleFingerIntermediateTip: .hand(.left, location: .joint(for: .middleFingerIntermediateTip))
        case .hand_left_joint_for_middleFingerTip: .hand(.left, location: .joint(for: .middleFingerTip))
        case .hand_left_joint_for_ringFingerMetacarpal: .hand(.left, location: .joint(for: .ringFingerMetacarpal))
        case .hand_left_joint_for_ringFingerKnuckle: .hand(.left, location: .joint(for: .ringFingerKnuckle))
        case .hand_left_joint_for_ringFingerIntermediateBase: .hand(.left, location: .joint(for: .ringFingerIntermediateBase))
        case .hand_left_joint_for_ringFingerIntermediateTip: .hand(.left, location: .joint(for: .ringFingerIntermediateTip))
        case .hand_left_joint_for_ringFingerTip: .hand(.left, location: .joint(for: .ringFingerTip))
        case .hand_left_joint_for_littleFingerMetacarpal: .hand(.left, location: .joint(for: .littleFingerMetacarpal))
        case .hand_left_joint_for_littleFingerKnuckle: .hand(.left, location: .joint(for: .littleFingerKnuckle))
        case .hand_left_joint_for_littleFingerIntermediateBase: .hand(.left, location: .joint(for: .littleFingerIntermediateBase))
        case .hand_left_joint_for_littleFingerIntermediateTip: .hand(.left, location: .joint(for: .littleFingerIntermediateTip))
        case .hand_left_joint_for_littleFingerTip: .hand(.left, location: .joint(for: .littleFingerTip))
        case .hand_left_joint_for_forearmWrist: .hand(.left, location: .joint(for: .forearmWrist))
        case .hand_left_joint_for_forearmArm: .hand(.left, location: .joint(for: .forearmArm))
        case .hand_right_thumbTip: .hand(.right, location: .thumbTip)
        case .hand_right_indexFingerTip: .hand(.right, location: .indexFingerTip)
        case .hand_right_wrist: .hand(.right, location: .wrist)
        case .hand_right_palm: .hand(.right, location: .palm)
        case .hand_right_aboveHand: .hand(.right, location: .aboveHand)
        case .hand_right_joint_for_wrist: .hand(.right, location: .joint(for: .wrist))
        case .hand_right_joint_for_thumbKnuckle: .hand(.right, location: .joint(for: .thumbKnuckle))
        case .hand_right_joint_for_thumbIntermediateBase: .hand(.right, location: .joint(for: .thumbIntermediateBase))
        case .hand_right_joint_for_thumbIntermediateTip: .hand(.right, location: .joint(for: .thumbIntermediateTip))
        case .hand_right_joint_for_thumbTip: .hand(.right, location: .joint(for: .thumbTip))
        case .hand_right_joint_for_indexFingerMetacarpal: .hand(.right, location: .joint(for: .indexFingerMetacarpal))
        case .hand_right_joint_for_indexFingerKnuckle: .hand(.right, location: .joint(for: .indexFingerKnuckle))
        case .hand_right_joint_for_indexFingerIntermediateBase: .hand(.right, location: .joint(for: .indexFingerIntermediateBase))
        case .hand_right_joint_for_indexFingerIntermediateTip: .hand(.right, location: .joint(for: .indexFingerIntermediateTip))
        case .hand_right_joint_for_indexFingerTip: .hand(.right, location: .joint(for: .indexFingerTip))
        case .hand_right_joint_for_middleFingerMetacarpal: .hand(.right, location: .joint(for: .middleFingerMetacarpal))
        case .hand_right_joint_for_middleFingerKnuckle: .hand(.right, location: .joint(for: .middleFingerKnuckle))
        case .hand_right_joint_for_middleFingerIntermediateBase: .hand(.right, location: .joint(for: .middleFingerIntermediateBase))
        case .hand_right_joint_for_middleFingerIntermediateTip: .hand(.right, location: .joint(for: .middleFingerIntermediateTip))
        case .hand_right_joint_for_middleFingerTip: .hand(.right, location: .joint(for: .middleFingerTip))
        case .hand_right_joint_for_ringFingerMetacarpal: .hand(.right, location: .joint(for: .ringFingerMetacarpal))
        case .hand_right_joint_for_ringFingerKnuckle: .hand(.right, location: .joint(for: .ringFingerKnuckle))
        case .hand_right_joint_for_ringFingerIntermediateBase: .hand(.right, location: .joint(for: .ringFingerIntermediateBase))
        case .hand_right_joint_for_ringFingerIntermediateTip: .hand(.right, location: .joint(for: .ringFingerIntermediateTip))
        case .hand_right_joint_for_ringFingerTip: .hand(.right, location: .joint(for: .ringFingerTip))
        case .hand_right_joint_for_littleFingerMetacarpal: .hand(.right, location: .joint(for: .littleFingerMetacarpal))
        case .hand_right_joint_for_littleFingerKnuckle: .hand(.right, location: .joint(for: .littleFingerKnuckle))
        case .hand_right_joint_for_littleFingerIntermediateBase: .hand(.right, location: .joint(for: .littleFingerIntermediateBase))
        case .hand_right_joint_for_littleFingerIntermediateTip: .hand(.right, location: .joint(for: .littleFingerIntermediateTip))
        case .hand_right_joint_for_littleFingerTip: .hand(.right, location: .joint(for: .littleFingerTip))
        case .hand_right_joint_for_forearmWrist: .hand(.right, location: .joint(for: .forearmWrist))
        case .hand_right_joint_for_forearmArm: .hand(.right, location: .joint(for: .forearmArm))
        case .head: .head
        }
    }
}
