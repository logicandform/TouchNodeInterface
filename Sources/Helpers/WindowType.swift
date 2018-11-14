//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import Cocoa


enum WindowType: Equatable {
    case record(Record)

    var size: CGSize {
        switch self {
        case .record:
            return CGSize(width: 416, height: 650)
        }
    }

    var level: NSWindow.Level {
        switch self {
        case .record:
            return style.recordWindowLevel
        }
    }

    static func == (lhs: WindowType, rhs: WindowType) -> Bool {
        switch (lhs, rhs) {
        case let (.record(lhsModel), .record(rhsModel)):
            return lhsModel.type == rhsModel.type && lhsModel.id == rhsModel.id
        }
    }
}
