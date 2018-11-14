//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


extension NSImage {

    func tinted(with tint: NSColor) -> NSImage {
        guard let tinted = self.copy() as? NSImage else {
            return self
        }
        tinted.lockFocus()
        tint.set()

        let imageRect = NSRect(origin: .zero, size: size)
        imageRect.fill(using: .sourceAtop)

        tinted.unlockFocus()
        return tinted
    }
}
