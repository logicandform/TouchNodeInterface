//  Copyright © 2018 JABT. All rights reserved.

import Cocoa


class CustomScrollView: NSScrollView {

    override var hasHorizontalScroller: Bool {
        get {
            return false
        }
        set {

        }
    }
}
