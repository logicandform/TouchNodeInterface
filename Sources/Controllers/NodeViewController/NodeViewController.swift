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
            setupNodeScene()
        }
    }


    // MARK: Setup

    private func setupView() {
        mainView.showsFPS = true
        mainView.showsNodeCount = true
    }

    private func setupNodeScene() {
        let scene = NodeScene(size: CGSize(width: mainView.bounds.width, height: mainView.bounds.height))
        scene.backgroundColor = style.darkBackgroundOpaque
        scene.scaleMode = .aspectFill
        EntityManager.instance.scene = scene
        scene.gestureManager = gestureManager
        mainView.presentScene(scene)
    }
}
