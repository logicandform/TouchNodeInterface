//  Copyright © 2018 JABT. All rights reserved.

import Cocoa
import SpriteKit
import GameplayKit
import MacGestures


class NodeViewController: NSViewController, NodeGestureResponder {
    static let storyboard = "Node"

    @IBOutlet private var mainView: SKView!

    var gestureManager: NodeGestureManager!
    private var initialized = false


    // MARK: Init

    static func instance() -> NodeViewController {
        return NSStoryboard(name: NodeViewController.storyboard, bundle: .main).instantiateInitialController() as! NodeViewController
    }


    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        gestureManager = NodeGestureManager(responder: self)
        TouchManager.instance.nodeGestureManager = gestureManager

        setupView()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if !initialized {
            initialized = true
            setupEntities()
            setupMainScene()
        }
    }


    // MARK: Setup

    private func setupView() {
        mainView.showsFPS = true
        mainView.showsNodeCount = true
    }

    private func setupEntities() {
        // TODO
//        RecordManager.instance.createEntities()
    }


    // MARK: Helpers

    private func setupMainScene() {
        let nodeScene = makeNodeScene()
        EntityManager.instance.scene = nodeScene
        nodeScene.gestureManager = gestureManager
        mainView.presentScene(nodeScene)
    }

    private func makeNodeScene() -> NodeScene {
        let nodeScene = NodeScene(size: CGSize(width: mainView.bounds.width, height: mainView.bounds.height))
        nodeScene.backgroundColor = style.darkBackgroundOpaque
        nodeScene.scaleMode = .aspectFill
        return nodeScene
    }
}