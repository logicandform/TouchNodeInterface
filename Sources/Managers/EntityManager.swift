//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// Class that manages all non-bounding node entities for the scene.
final class EntityManager {
    static let instance = EntityManager()

    /// The scene that record nodes are added to
    var scene: NodeScene!

    /// Set of all entities for type and id
    private(set) var entitiesForType: [RecordType: [Int: [RecordEntity]]] = [:]

    /// List of all GKComponentSystems. The systems will be updated in order. The order is defined to match assumptions made within components.
    private lazy var componentSystems: [GKComponentSystem] = {
        let movementSystem = GKComponentSystem(componentClass: RecordMovementComponent.self)
        let physicsSystem = GKComponentSystem(componentClass: RecordPhysicsComponent.self)
        return [movementSystem, physicsSystem]
    }()

    private struct Constants {
        static let maxRelatedLevel = 4
        static let maxEntitiesPerLevel = 30
    }


    // MARK: Init

    /// Use singleton
    private init() {
        for type in RecordType.allCases {
            entitiesForType[type] = [:]
        }
    }


    // MARK: API

    /// Creates and stores record entities from all records from database
    func createEntity(record: Record, levels: RelatedLevels) {
        let entity = RecordEntity(record: record, levels: levels)
        store(entity)
        addComponents(to: entity)
    }

    func entities(of type: RecordType) -> [RecordEntity] {
        let entities = entitiesForType[type] ?? [:]
        return entities.reduce([]) { $0 + $1.value }
    }

    /// If entity is a duplicate it will be removed from the scene, else resets entity.
    func release(_ entity: RecordEntity) {
        guard let entities = entitiesForType[entity.record.type]?[entity.record.id] else {
            return
        }

        if entities.count > 1 {
            entity.set(state: .remove)
        } else {
            // TODO: make province entity
            if entity.record.type == .city {
                let dx = CGFloat.random(in: style.themeDxRange)
                entity.set(state: .drift(dx: dx))
            } else {
                entity.set(state: .reset)
            }
        }
    }

    /// Removes an entity from the scene and local cache
    func remove(_ entity: RecordEntity) {
        guard entity.state == .remove, let entities = entitiesForType[entity.record.type]?[entity.record.id] else {
            fatalError("Entity should be marked for removal. Call")
        }

        if let index = entities.index(where: { $0 === entity }) {
            removeComponents(from: entity)
            entity.node.removeFromParent()
            entitiesForType[entity.record.type]?[entity.record.id]?.remove(at: index)
            scene.gestureManager.remove(entity.node)
        }
    }

    func requestEntityLevels(for entity: RecordEntity, in cluster: NodeCluster) -> EntityLevels {
        let currentEntities = flatten(cluster.entitiesForLevel).union([cluster.selectedEntity])
        var result = EntityLevels()

        // Build levels for the new entity
        for (level, records) in entity.relatedRecordsForLevel.enumerated() {
            // Prioritize entities that already exist in the cluster
            var entitiesForLevel = entities(for: records, from: currentEntities, size: Constants.maxEntitiesPerLevel)

            // Request the remaining entities up to to allowed size per level
            let remainingSpace = Constants.maxEntitiesPerLevel - entitiesForLevel.count
            let currentRecords = Set(entitiesForLevel.map { $0.record })
            let requestedRecords = records.subtracting(currentRecords)
            let requestedEntities = requestEntities(from: requestedRecords, size: remainingSpace, for: cluster, level: level)
            entitiesForLevel.formUnion(requestedEntities)

            // Don't insert empty levels
            if entitiesForLevel.isEmpty {
                break
            }
            result.insert(entitiesForLevel, at: level)
        }

        return result
    }

    /// Returns a subset of the given entities that exist in the set of proxies up to size
    private func entities(for records: Set<Record>, from entities: Set<RecordEntity>, size: Int) -> Set<RecordEntity> {
        let filtered = entities.filter { records.contains($0.record) }
        var result = Set<RecordEntity>()
        for (index, entity) in filtered.enumerated() {
            if index < size {
                result.insert(entity)
            }
        }
        return result
    }

    func createCopy(of entity: RecordEntity, level: Int) -> RecordEntity {
        let copy = entity.clone()
        store(copy)
        addComponents(to: copy)
        copy.initialPosition = entity.initialPosition
        copy.set(position: entity.position)
        copy.node.scale(to: entity.node.size)
        let showTitle = NodeCluster.showTitleFor(level: level)
        copy.node.titleNode.alpha = showTitle ? 1 : 0
        copy.previousCluster = entity.cluster
        scene.addChild(copy.node)
        scene.addGestures(to: copy.node)
        return copy
    }

    /// Updates all component systems that the EntityManager is responsible for
    func update(_ deltaTime: CFTimeInterval) {
        for componentSystem in componentSystems {
            componentSystem.update(deltaTime: deltaTime)
        }
    }


    // MARK: Helpers

    /// Returns a random subset of entities associated with the given proxies up to a given size, entities in another cluster will be duplicated.
    private func requestEntities(from records: Set<Record>, size: Int, for cluster: NodeCluster, level: Int) -> Set<RecordEntity> {
        let shuffled = records.shuffled()
        let max = min(size, shuffled.count)
        var result = Set<RecordEntity>()

        for index in (0 ..< max) {
            let proxy = shuffled[index]
            if let entityForProxy = getEntity(for: proxy) {
                // TODO make province
                if proxy.type == .city {
                    let copy = createCopy(of: entityForProxy, level: level)
                    copy.cluster = cluster
                    result.insert(copy)
                } else if let current = entityForProxy.cluster, current != cluster {
                    let copy = createCopy(of: entityForProxy, level: level)
                    copy.cluster = cluster
                    result.insert(copy)
                } else {
                    entityForProxy.cluster = cluster
                    result.insert(entityForProxy)
                }
            }
        }
        return result
    }

    private func store(_ entity: RecordEntity) {
        if entitiesForType[entity.record.type]?[entity.record.id] == nil {
            entitiesForType[entity.record.type]?[entity.record.id] = [entity]
        } else {
            entitiesForType[entity.record.type]?[entity.record.id]!.append(entity)
        }
    }

    /// Returns entity for given record, prioritizing records that are not already clustered
    private func getEntity(for record: Record) -> RecordEntity? {
        guard let entities = entitiesForType[record.type]?[record.id] else {
            return nil
        }

        if let unclustered = entities.first(where: { $0.cluster == nil }) {
            return unclustered
        }

        return entities.first
    }

    private func addComponents(to entity: RecordEntity) {
        for componentSystem in componentSystems {
            componentSystem.addComponent(foundIn: entity)
        }
    }

    private func removeComponents(from entity: RecordEntity) {
        for componentSystem in componentSystems {
            componentSystem.removeComponent(foundIn: entity)
        }
    }

    private func flatten(_ levels: EntityLevels) -> Set<RecordEntity> {
        return levels.reduce(Set<RecordEntity>()) { return $0.union($1) }
    }
}
