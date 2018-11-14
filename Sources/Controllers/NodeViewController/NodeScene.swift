//  Copyright © 2018 JABT. All rights reserved.

import SpriteKit
import GameplayKit
import MacGestures


class NodeScene: SKScene, SKPhysicsContactDelegate {

    var gestureManager: NodeGestureManager!
    private var clusterForID = [Int: NodeCluster]()
    private var selectedEntity: RecordEntity?

    private struct Constants {
        static let windowDisplayOffset: CGFloat = 30
        static let maximumNumberOfClusters = 18
        static let draggingImpulseFactor: CGFloat = 4
        static let panRecognizedThreshold: CGFloat = 10
    }

    private struct Keys {
        static let id = "id"
        static let app = "app"
        static let type = "type"
        static let position = "position"
    }


    // MARK: Life-Cycle

    override func didMove(to view: SKView) {
        super.didMove(to: view)

        setupSystemGestures()
        setupPhysics()
        setupProvinces()
        setupEntities()
    }

    override func update(_ currentTime: TimeInterval) {
        super.update(currentTime)

        EntityManager.instance.update(currentTime)
        for cluster in clusterForID.values {
            cluster.update(currentTime)
        }

        for node in children {
            node.zRotation = 0
        }
    }


    // MARK: API

    func addGestures(to node: SKNode) {
        let tapGesture = TapGestureRecognizer()
        gestureManager.add(tapGesture, to: node)
        tapGesture.gestureUpdated = { [weak self] gesture in
            self?.handleTapGesture(gesture)
        }

        let panGesture = PanGestureRecognizer(recognizedThreshold: Constants.panRecognizedThreshold, friction: .low)
        gestureManager.add(panGesture, to: node)
        panGesture.gestureUpdated = { [weak self] gesture in
            self?.handlePanGesture(gesture)
        }
    }

    /// Return an array containing the first record node hit before a cluster layer.
    override func nodes(at p: CGPoint) -> [SKNode] {
        let nodes = super.nodes(at: p)

        for node in nodes {
            if node is ClusterLayerNode && node.contains(p) {
                return []
            }
            if node is RecordNode && node.contains(p) {
                return [node]
            }
        }

        return []
    }

    func remove(cluster: NodeCluster) {
        cluster.reset()
        clusterForID.removeValue(forKey: cluster.id)
    }


    // MARK: Setup

    private func setupSystemGestures() {
        guard let view = view else {
            return
        }

        let nsTapGesture = NSClickGestureRecognizer(target: self, action: #selector(handleSystemClickGesture(_:)))
        view.addGestureRecognizer(nsTapGesture)

        let nsPanGesture = NSPanGestureRecognizer(target: self, action: #selector(handleSystemPanGesture(_:)))
        view.addGestureRecognizer(nsPanGesture)
    }

    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }

    private func setupProvinces() {
        guard let scene = scene else {
            return
        }

        let provinces = EntityManager.instance.entities(of: .province)

        for province in provinces {
            let dx = CGFloat.random(in: style.provinceDxRange)
            let x = CGFloat.random(in: 0 ... scene.frame.width)
            let y = CGFloat.random(in: 0 ... scene.frame.height)
            province.set(state: .drift(dx: dx))

            if let recordNode = province.component(ofType: RecordRenderComponent.self)?.recordNode {
                recordNode.position = CGPoint(x: x, y: y)
                addChild(recordNode)
                addGestures(to: recordNode)
            }
        }
    }

    private func setupEntities() {
        var entityTypes = Set(RecordType.allCases)
        entityTypes.remove(.province)
        let entities = entityTypes.reduce([]) { $0 + EntityManager.instance.entities(of: $1) }
        let spacing = frame.width / CGFloat(entities.count / 2)
        let nodeRadius = style.defaultNodeSize.width / 2

        for (index, entity) in entities.enumerated() {
            let x = spacing * CGFloat(index / 2)
            let y = index.isEven ? -nodeRadius : frame.height + nodeRadius
            entity.initialPosition = CGPoint(x: x, y: y)
            if let recordNode = entity.component(ofType: RecordRenderComponent.self)?.recordNode {
                recordNode.position = CGPoint(x: x, y: y)
                recordNode.alpha = 0
                addChild(recordNode)
                addGestures(to: recordNode)
            }
        }
    }


    // MARK: Gesture Handlers

    private func handleTapGesture(_ gesture: GestureRecognizer) {
        guard let tap = gesture as? TapGestureRecognizer, let recordNode = gestureManager.node(for: tap) as? RecordNode, let position = tap.position else {
            return
        }

        switch tap.state {
        case .ended:
            select(recordNode, at: position)
        default:
            return
        }
    }

    private func handlePanGesture(_ gesture: GestureRecognizer) {
        guard let scene = scene, let pan = gesture as? PanGestureRecognizer, let node = gestureManager.node(for: pan) as? RecordNode, let entity = node.entity as? RecordEntity, entity.state.pannable else {
            return
        }

        // Ensure that the state for the entity is dragging if the gesture state is not in its recognized state
        if pan.state != .recognized && entity.state != .dragging {
            return
        }

        let position = node.position + pan.delta

        switch pan.state {
        case .recognized:
            entity.set(state: .dragging)
            entity.dragVelocity = pan.delta
            entity.set(position: position)
            if entity.isSelected {
                entity.cluster?.set(position: position)
            }
        case .momentum:
            let positionInScene = contained(position: position, in: scene, for: entity)
            entity.set(position: positionInScene)
            entity.dragVelocity = pan.delta
            if entity.isSelected {
                entity.cluster?.set(position: position)
            }
        case .ended:
            entity.dragVelocity = nil
        case .possible, .failed:
            finishDrag(for: entity)
        default:
            return
        }
    }

    /// Contains the position of the entity to the scene vertically and horizontally (if entity is not controlling cluster).
    private func contained(position: CGPoint, in scene: SKScene, for entity: RecordEntity) -> CGPoint {
        let radius = entity.node.size.width / 2
        var x = position.x
        var y = position.y

        // Only contain x position to scene if entity does not have a cluster
        if entity.cluster == nil, x > scene.frame.width + radius {
            x = -entity.node.size.width * 2
        }
        // Contain y position within the scene
        if y < -radius {
            y = scene.frame.height + radius
        } else if y > scene.frame.height + radius {
            y = -radius
        }
        return CGPoint(x: x, y: y)
    }

    private func finishDrag(for entity: RecordEntity) {
        // Check if entity is controlling a cluster
        if entity.isSelected {
            // Check if entity is still within the frame of the application
            if frame(contains: entity) {
                entity.set(state: .selected)
            } else {
                entity.cluster?.reset()
            }
        } else if let cluster = entity.cluster {
            // Update the entity given the cluster current selected entity
            if let level = cluster.level(for: entity) {
                entity.hasCollidedWithLayer = false
                entity.set(level: level)
                entity.set(state: .seekLevel(level))

                // If entity was dragged outside of its cluster, duplicate entity with its own cluster
                if !cluster.intersects(entity) && frame(contains: entity), availableClusterID() != nil {
                    let copy = EntityManager.instance.createCopy(of: entity, level: level)
                    let newCluster = createCluster(with: copy)
                    newCluster?.select(copy)
                }
            } else {
                EntityManager.instance.release(entity)
            }
        } else {
            if entity.record.type == .province {
                let dx = CGFloat.random(in: style.provinceDxRange)
                entity.set(state: .drift(dx: dx))
            } else {
                EntityManager.instance.release(entity)
            }
        }
    }

    @objc
    private func handleSystemClickGesture(_ recognizer: NSClickGestureRecognizer) {
        let clickPosition = recognizer.location(in: recognizer.view)
        let point = convertPoint(fromView: clickPosition)
        guard let node = nodes(at: point).first as? RecordNode else {
            return
        }

        switch recognizer.state {
        case .ended:
            select(node, at: point)
        default:
            return
        }
    }

    @objc
    private func handleSystemPanGesture(_ recognizer: NSPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            let pannedPosition = recognizer.location(in: recognizer.view)
            let point = convertPoint(fromView: pannedPosition)
            if let recordNode = nodes(at: point).first as? RecordNode, let entity = recordNode.entity as? RecordEntity, entity.state.pannable {
                selectedEntity = entity
                selectedEntity?.set(state: .dragging)
            }
        case .changed:
            let position = recognizer.location(in: recognizer.view)
            let velocity = recognizer.velocity(in: recognizer.view)
            selectedEntity?.set(position: position)
            selectedEntity?.dragVelocity = velocity.asVector / 60
            if let entity = selectedEntity, entity.isSelected {
                entity.cluster?.set(position: position)
            }
        case .ended:
            guard let selectedEntity = selectedEntity else {
                return
            }

            let position = recognizer.location(in: recognizer.view)
            selectedEntity.set(position: position)
            selectedEntity.dragVelocity = nil
            if selectedEntity.isSelected {
                selectedEntity.cluster?.set(position: position)
            }

            if selectedEntity.state == .dragging {
                finishDrag(for: selectedEntity)
                self.selectedEntity = nil
            }
        default:
            return
        }
    }


    // MARK: SKPhysicsContactDelegate

    func didBegin(_ contact: SKPhysicsContact) {
        guard let lhs = contact.bodyA.node?.entity as? RecordEntity, let rhs = contact.bodyB.node?.entity as? RecordEntity else {
            return
        }

        /// When a dragged node contacts a drifting node, apply an impulse based on the velocity of the dragged node
        if lhs.state == .dragging, let velocity = lhs.dragVelocity {
            if case .drift(_) = rhs.state {
                let impulse = contact.contactNormal * CGFloat(velocity.magnitude) * Constants.draggingImpulseFactor
                rhs.physicsBody.applyImpulse(impulse)
            }
        } else if rhs.state == .dragging, let velocity = rhs.dragVelocity {
            if case .drift(_) = lhs.state {
                let impulse = contact.contactNormal * -CGFloat(velocity.magnitude) * Constants.draggingImpulseFactor
                lhs.physicsBody.applyImpulse(impulse)
            }
        }
    }


    // MARK: Helpers

    /// Sets up all the data relationships for the tapped node and starts the physics interactions
    private func select(_ node: RecordNode, at position: CGPoint) {
        guard let entity = node.entity as? RecordEntity, entity.state.tappable else {
            return
        }

        guard let cluster = nodeCluster(for: entity) else {
            return
        }

        switch entity.state {
        case .static, .drift:
            cluster.select(entity)
        case .seekEntity:
            if entity.hasCollidedWithLayer {
                cluster.select(entity)
            }
        case .selected:
            // Only allow actions once the node is aligned with its cluster
            if aligned(entity, with: cluster) {
                if node.openButton(contains: position) {
                    displayWindow(for: node.record, at: position)
                } else if node.closeButton(contains: position) {
                    remove(cluster: cluster)
                }
            }
        default:
            return
        }
    }

    private func nodeCluster(for entity: RecordEntity) -> NodeCluster? {
        if let current = entity.cluster {
            return current
        }

        return createCluster(with: entity)
    }

    private func createCluster(with entity: RecordEntity) -> NodeCluster? {
        guard let id = availableClusterID() else {
            return nil
        }

        let cluster = NodeCluster(id: id, scene: self, entity: entity)
        clusterForID[id] = cluster
        return cluster
    }

    private func availableClusterID() -> Int? {
        for id in 1 ... Constants.maximumNumberOfClusters {
            if clusterForID[id] == nil {
                return id
            }
        }

        return nil
    }

    private func frame(contains entity: RecordEntity) -> Bool {
        return frame.intersects(entity.node.frame)
    }

    /// Determines if a given entity is aligned with its cluster
    private func aligned(_ entity: RecordEntity, with cluster: NodeCluster) -> Bool {
        let entityX = Int(entity.position.x)
        let entityY = Int(entity.position.y)
        let clusterX = Int(cluster.center.x)
        let clusterY = Int(cluster.center.y)
        return entityX == clusterX && entityY == clusterY
    }

    private func displayWindow(for record: Record, at location: CGPoint) {
        guard let window = view?.window else {
            return
        }

        let windowType = WindowType.record(record)
        let originX = location.x - windowType.size.width / 2
        let originY = max(style.windowMargins, location.y - windowType.size.height - Constants.windowDisplayOffset)
        let positionInScreen = window.frame.origin + CGPoint(x: originX, y: originY)
        WindowManager.instance.display(windowType, at: positionInScreen)
    }
}
