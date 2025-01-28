import RealityKit

extension Entity {
    convenience init(axesWithLength length: Float) {
        self.init()
        let origin = ModelEntity(mesh: .generateSphere(radius: length / 5), materials: [UnlitMaterial(color: .white)])
        addChild(origin)
        let axis = ModelEntity(mesh: .generateCylinder(height: length, radius: length / 10), materials: [])
        let axes = [axis.clone(recursive: true), axis.clone(recursive: true), axis.clone(recursive: true)]
        axes[0].model?.materials = [UnlitMaterial(color: .red)]
        axes[1].model?.materials = [UnlitMaterial(color: .green)]
        axes[2].model?.materials = [UnlitMaterial(color: .blue)]
        axes[0].transform = .init(rotation: .init(angle: .pi / 2, axis: .init(0, 0, 1)), translation: .init(length / 2, 0, 0))
        axes[1].transform = .init(rotation: .init(.identity), translation: .init(0, length / 2, 0))
        axes[2].transform = .init(rotation: .init(angle: .pi / 2, axis: .init(1, 0, 0)), translation: .init(0, 0, length / 2))
        axes.forEach { addChild($0) }
    }
}

extension Entity {
    func findSkeltalPosesEntity() -> ModelEntity? {
        if let model = (self as? ModelEntity)?.model, !model.mesh.contents.skeletons.isEmpty { return self as? ModelEntity }
        return children.lazy.compactMap {$0.findSkeltalPosesEntity()}.first
    }
}

extension Entity {
    func recursiveModelEntities() -> [ModelEntity] {
        [self as? ModelEntity].compactMap {$0} + children.flatMap {$0.recursiveModelEntities()}
    }
}
