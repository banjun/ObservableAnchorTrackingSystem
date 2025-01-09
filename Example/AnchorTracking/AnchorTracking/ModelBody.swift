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
    }

    func setTransforms(transforms: [AnchoringComponent.Target: Transform]) {
        anchorEntities.forEach {$1.isEnabled = false}
        transforms.forEach { target, transform in
            anchorEntities[target]?.transform = transform
            anchorEntities[target]?.isEnabled = true
        }
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0).targetedToEntity(origin).onChanged { [weak self] value in
            guard let self, let rootParent = root.parent else { return }
            var location: SIMD3<Float> = value.convert(value.location3D, from: .local, to: rootParent)
            location.y = 0
            let limit: Float = 3
            location = length(location) < limit ? location : (normalize(location) * limit)
            let rotation: simd_quatf = .init(.identity)
            self.transform = Transform(rotation: rotation, translation: location)
        }
    }
}
