import RealityKit
import Observation
import ARKit
import QuartzCore

public struct ObservableAnchorEntityComponent: Component {
    public init() {}
}

public struct ObservableAnchorTrackingSystem: System {
    @MainActor public static let observable: ObservableValue = .init()
    @Observable public final class ObservableValue {
        public fileprivate(set) var transforms: [AnchoringComponent.Target: Transform] = [:]
        public fileprivate(set) var error: Error?
    }
    public enum Error: Swift.Error {
        case arkit(Swift.Error)
    }
    
    let spatialTrackingSession = SpatialTrackingSession()
    let arkitSession = ARKitSession()
    let worldTrackingProvider = WorldTrackingProvider()

    public init(scene: RealityKit.Scene) {
        run()
    }

    @MainActor public func run() {
        Self.observable.error = nil
        Task {
            NSLog("%@", "\(#function): starting spatialTrackingSession = \(String(describing: spatialTrackingSession))")
            await spatialTrackingSession.run(.init(tracking: [.hand]))
        }
        Task {
            do {
                NSLog("%@", "\(#function): starting arkitSession = \(String(describing: arkitSession))")
                try await arkitSession.run([worldTrackingProvider])
            } catch {
                Self.observable.error = .arkit(error)
                NSLog("%@", "\(#function): arkitSession.run error = \(String(describing: error))")
            }
        }
    }

    public func update(context: SceneUpdateContext) {
        Self.observable.transforms = context.entities(matching: .init(where: .has(ObservableAnchorEntityComponent.self)), updatingSystemWhen: .rendering).reduce(into: [:]) {
            guard let e = $1 as? AnchorEntity else { return }
            $0[e.anchoring.target] = Transform(matrix: e.transformMatrix(relativeTo: nil))

            // AnchorEntity(.head) does not update. fallback to DeviceAnchor. requires WorldTrackingProvider is running by someone
            if case .head = e.anchoring.target, $0[e.anchoring.target] == .identity {
                $0[.head] = nil
                guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
                switch deviceAnchor.trackingState {
                case .untracked: break
                case .orientationTracked: break
                case .tracked: $0[.head] = Transform(matrix: deviceAnchor.originFromAnchorTransform)
                @unknown default: break
                }
            }
        }
    }

    @MainActor
    public static func createAnchorTargetEntities(anchorTargets: [AnchoringComponent.Target], withDebugAxes: Bool = false) -> Entity {
        Entity(anchorTargets: anchorTargets, withDebugAxes: withDebugAxes)
    }
}
