//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MONode
import MacGestures


final class TouchManager: SocketManagerDelegate {
    static let instance = TouchManager()

    var timelineGestureManager: GestureManager?
    private var socketManager: SocketManager?
    private var managersForTouch = [Touch: (NSWindow, GestureManager)]()
    private var touchesForAppID = [Int: Set<Touch>]()
    private var touchNeedsUpdate = [Touch: Bool]()


    // MARK: Init

    private init() { }


    // MARK: API

    func setupTouchSocket() {
        socketManager = SocketManager(networkConfiguration: NetworkConfiguration(nodePort: Configuration.touchPort))
        socketManager?.delegate = self
    }


    // MARK: SocketManagerDelegate

    func handlePacket(_ packet: Packet) {
        guard let touch = Touch(from: packet) else {
            return
        }

        // Convert the touch's position to the coordinates of the screen
        convert(touch, toScreen: touch.screen)

        // Check if the touch landed on a window, else notify the proper map application
        if let manager = manager(of: touch) {
            manager.handle(touch)
        } else {
            timelineGestureManager?.handle(touch)
        }
    }

    func handleError(_ message: String) {
        print(message)
    }


    // MARK: Helpers

    /// Calculates the manager and stores it locally for fast access to windows in the hierarchy
    private func manager(of touch: Touch) -> GestureManager? {
        switch touch.state {
        case .down:
            if let (window, manager) = calculateWindow(of: touch) {
                window.makeKeyAndOrderFront(self)
                managersForTouch[touch] = (window, manager)
                return manager
            }
        case .moved:
            if let (_, manager) = managersForTouch[touch] {
                return manager
            }
        case .up:
            if let (_, manager) = managersForTouch[touch] {
                managersForTouch.removeValue(forKey: touch)
                return manager
            }
        }

        return nil
    }

    /// Returns a gesture manager that owns the given touch, else nil.
    private func calculateWindow(of touch: Touch) -> (NSWindow, GestureManager)? {
        let windows = WindowManager.instance.windows.sorted(by: { $0.key.orderedIndex < $1.key.orderedIndex })

        if touch.state == .down {
            if let (window, manager) = windows.first(where: { $0.key.frame.contains(touch.position) && windowSubviews($0.key, contains: touch, in: $0.value.responder) }) {
                return (window, manager)
            }
        } else {
            if let (window, manager) = windows.first(where: { $0.value.owns(touch) && windowSubviews($0.key, contains: touch, in: $0.value.responder) }) {
                return (window, manager)
            }
        }

        return nil
    }

    private func windowSubviews(_ window: NSWindow, contains touch: Touch, in responder: GestureResponder) -> Bool {
        return responder.subview(contains: touch.position.transformed(to: window.frame))
    }

    /// Updates the touches for map dictionary when a touch down or up occurs.
    private func updateTouchesForApp(with touch: Touch, for app: Int) {
        switch touch.state {
        case .down:
            if touchesForAppID[app] != nil {
                touchesForAppID[app]!.insert(touch)
            } else {
                touchesForAppID[app] = Set([touch])
            }
        case .up:
            if touchesForAppID[app] != nil {
                touchesForAppID[app]!.remove(touch)
            }
        case .moved:
            return
        }
    }

    /// Converts a position received from a touch screen to the coordinate of the current devices bounds.
    private func convert(_ touch: Touch, toScreen screen: Int) {
        let screen = NSScreen.at(position: screen)
        let xPos = (touch.position.x / Configuration.touchScreen.touchSize.width * CGFloat(screen.frame.width)) + screen.frame.origin.x
        let yPos = (1 - touch.position.y / Configuration.touchScreen.touchSize.height) * CGFloat(screen.frame.height)
        touch.position = CGPoint(x: xPos, y: yPos)
    }
}
