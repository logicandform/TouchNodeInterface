//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit
import MacGestures


final class WindowManager {
    static let instance = WindowManager()

    private(set) var windows = [NSWindow: GestureManager]()
    private var controllerForRecord = [Record: BaseViewController]()


    // MARK: Init

    /// Use singleton instance
    private init() { }


    // MARK: API

    func closeWindow(for controller: BaseViewController) {
        if let (window, _) = windows.first(where: { $0.value === controller.gestureManager }) {
            windows.removeValue(forKey: window)
            window.close()

            if let info = controllerForRecord.first(where: { $0.value == controller }) {
                controllerForRecord.removeValue(forKey: info.key)
            }
        }
    }

    @discardableResult
    func display(_ type: WindowType, at origin: CGPoint = .zero) -> BaseViewController? {
        let window = WindowFactory.window(for: type, at: origin)

        if let controller = window.contentViewController as? BaseViewController {
            windows[window] = controller.gestureManager
            return controller
        }

        return nil
    }

    /// If the controller is not draggable within the applications bounds, dismiss the window.
    func checkBounds(of controller: BaseViewController) {
        let applicationScreens = NSScreen.screens.dropFirst()
        let first = applicationScreens.first?.frame ?? .zero
        let applicationFrame = applicationScreens.reduce(first) { $0.union($1.frame) }
        if !controller.draggableInside(bounds: applicationFrame) {
            controller.close()
        }
    }


    // MARK: Receiving Notifications

    private func display(_ record: Record, for windowType: WindowType, at origin: CGPoint) {
        if let controller = controllerForRecord[record] {
            controller.setWindow(origin: origin, animate: true)
        } else if let controller = display(windowType, at: origin) {
            controllerForRecord[record] = controller
        }
    }
}
