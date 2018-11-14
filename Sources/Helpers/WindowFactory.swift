//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


final class WindowFactory {


    // MARK: API

    static func window(for type: WindowType, at origin: CGPoint) -> NSWindow {
        let viewController = controller(for: type)
        viewController.view.setFrameSize(type.size)
        let window = BorderlessWindow(frame: CGRect(origin: origin, size: type.size), controller: viewController, level: type.level)
        window.makeKeyAndOrderFront(self)
        return window
    }


    // MARK: Helpers

    private static func controller(for type: WindowType) -> NSViewController {
        switch type {
        case let .record(model):
            let storyboard = NSStoryboard(name: RecordViewController.storyboard, bundle: .main)
            let recordViewController = storyboard.instantiateInitialController() as! RecordViewController
            recordViewController.record = model
            recordViewController.type = type
            return recordViewController
        }
    }
}
