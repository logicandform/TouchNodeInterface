//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordType: String, CaseIterable {
    case city
    case event
    case individual

    var color: NSColor {
        switch self {
        case .city:
            return style.schoolColor
        case .event:
            return style.eventColor
        case .individual:
            return style.individualColor
        }
    }

    var sortOrder: Int {
        switch self {
        case .city:
            return 1
        case .event:
            return 2
        case .individual:
            return 3
        }
    }

    var placeholder: NSImage {
        switch self {
        case .city:
            return NSImage(named: "city-icon")!
        case .event:
            return NSImage(named: "event-icon")!
        case .individual:
            return NSImage(named: "individual-icon")!
        }
    }
}
