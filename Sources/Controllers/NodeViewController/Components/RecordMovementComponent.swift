//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import SpriteKit
import GameplayKit


/// A 'GKComponent' that provides different types of physics movement based on the current entities state.
class RecordMovementComponent: GKComponent {

    private struct Constants {
        static let strength = Configuration.touchScreen.frameSize.width / 2
        static let dt: CGFloat = 1 / 5000
        static let speed: CGFloat = 500
        static let driftingDisplacement: CGFloat = 0.5
    }


    // MARK: Lifecycle

    override func update(deltaTime seconds: TimeInterval) {
        super.update(deltaTime: seconds)
        guard let entity = entity as? RecordEntity else {
            return
        }

        switch entity.state {
        case let .drift(dx):
            drift(dx: dx)
        case .seekEntity(let entity):
            seek(entity)
        case .seekLevel(let level):
            move(to: level)
        case .static, .selected, .dragging, .reset, .remove:
            break
        }
    }


    // MARK: Physics Movement

    /// Applies minimum horizontal velocity and contains nodes to the scene
    private func drift(dx: CGFloat) {
        guard let entity = entity as? RecordEntity, let scene = entity.node.scene else {
            return
        }

        entity.physicsBody.velocity.dx = max(dx, entity.physicsBody.velocity.dx)
        let radius = entity.node.size.width / 2
        let isDrifting = abs(entity.physicsBody.velocity.dx - dx) < Constants.driftingDisplacement

        if entity.position.x > scene.frame.width + radius {
            // If node drifts off screen with expected velocity, update node with new y position
            let y = isDrifting ? CGFloat.random(in: radius ... scene.frame.height - radius) : entity.position.y
            entity.set(position: CGPoint(x: -entity.node.size.width * 2, y: y))
            let dx = CGFloat.random(in: style.provinceDxRange)
            entity.set(state: .drift(dx: dx))
        }
        if entity.position.y < -radius {
            entity.set(position: CGPoint(x: entity.position.x, y: scene.frame.height + radius))
        }
        if entity.position.y > scene.frame.height + radius {
            entity.set(position: CGPoint(x: entity.position.x, y: -radius))
        }
        // If entity is drifting near the edge of the screen, apply vertical velocity
        if isDrifting {
            if entity.position.y < radius {
                entity.physicsBody.velocity.dy = 10
            } else if entity.position.y > scene.frame.height - radius {
                entity.physicsBody.velocity.dy = -10
            }
        }
    }

    /// Applies appropriate physics that moves the entity to the appropriate higher level before entering next state and setting its bitMasks
    private func move(to level: Int) {
        guard let entity = entity as? RecordEntity, let cluster = entity.cluster, let referenceNode = cluster.layerForLevel[level]?.renderComponent.layerNode else {
            return
        }

        // Find the unit vector from the distance between this component's entity and the center root node
        let deltaX = entity.position.x - referenceNode.position.x
        let deltaY = entity.position.y - referenceNode.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)
        let distanceBetweenNodeAndCenter = distanceOf(x: deltaX, y: deltaY)

        var unitVector: CGVector
        if distanceBetweenNodeAndCenter > 0 {
            unitVector = CGVector(dx: displacement.dx / distanceBetweenNodeAndCenter, dy: displacement.dy / distanceBetweenNodeAndCenter)
        } else {
            unitVector = CGVector(dx: 0.5, dy: 0)
        }

        // Find the difference in distance. This gives the total distance that is left to travel for the node
        guard let currentLevel = entity.clusterLevel.currentLevel, let currentLevelBoundingEntityComponent = cluster.layerForLevel[currentLevel]?.renderComponent else {
            return
        }

        let overlapingSibling = entity.physicsBody.allContactedBodies().contains { $0.node is RecordNode }
        let wasSelected = entity.clusterLevel.previousLevel == NodeCluster.selectedEntityLevel
        let r2 = overlapingSibling || wasSelected ? currentLevelBoundingEntityComponent.maxRadius : currentLevelBoundingEntityComponent.minRadius
        let r1 = distanceBetweenNodeAndCenter

        if (r2 - r1) < -entity.bodyRadius {
            entity.set(state: .seekEntity(cluster.selectedEntity))
        } else {
            entity.physicsBody.velocity = CGVector(dx: Constants.speed * unitVector.dx, dy: Constants.speed * unitVector.dy)
        }
    }

    /// Applies appropriate physics that emulates a gravitational pull between this component's entity and the entity that it should seek
    private func seek(_ targetEntity: RecordEntity) {
        guard let entity = entity as? RecordEntity else {
            return
        }

        // Check the radius between its own entity and the nodeToSeek, and apply the appropriate physics
        let deltaX = targetEntity.position.x - entity.position.x
        let deltaY = targetEntity.position.y - entity.position.y
        let displacement = CGVector(dx: deltaX, dy: deltaY)
        let radius = distanceOf(x: deltaX, y: deltaY)

        let targetEntityMass = style.nodePhysicsBodyMass * Constants.strength * radius
        let entityMass = style.nodePhysicsBodyMass * Constants.strength * radius

        let unitVector = CGVector(dx: displacement.dx / radius, dy: displacement.dy / radius)
        let force = (targetEntityMass * entityMass) / (radius * radius)
        let impulse = CGVector(dx: force * Constants.dt * unitVector.dx, dy: force * Constants.dt * unitVector.dy)

        entity.physicsBody.velocity = CGVector(dx: entity.physicsBody.velocity.dx + impulse.dx, dy: entity.physicsBody.velocity.dy + impulse.dy)
    }

    private func distanceOf(x: CGFloat, y: CGFloat) -> CGFloat {
        let dX = Float(x)
        let dY = Float(y)
        return CGFloat(hypotf(dX, dY))
    }
}
