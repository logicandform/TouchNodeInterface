//  Copyright © 2018 slant. All rights reserved.

import Foundation
import MONode

public extension NetworkConfiguration {

    public init(nodePort: UInt16) {
        self.init()
        self.nodePort = nodePort
    }
}
