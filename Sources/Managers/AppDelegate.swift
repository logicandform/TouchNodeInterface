//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


let style = Style()


struct Configuration {
    static let touchPort: UInt16 = 13001
    static let touchScreenPosition = 1
    static let touchScreen = TouchScreen.pct2485
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        TouchManager.instance.setupTouchSocket()
        RecordManager.instance.initialize()
        EntityManager.instance.initialize()
        setupApplication()
    }


    // MARK: Helpers

    private func setupApplication() {
        let screen = NSScreen.at(position: Configuration.touchScreenPosition)
        let nodeController = NodeViewController.instance()
        let nodeWindow = BorderlessWindow(frame: screen.frame, controller: nodeController, level: style.nodeWindowLevel)
        nodeWindow.setFrame(screen.frame, display: true)
        nodeWindow.makeKeyAndOrderFront(self)
    }
}
