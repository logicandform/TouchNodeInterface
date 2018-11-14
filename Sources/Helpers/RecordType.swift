//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import AppKit


enum RecordType: String, CaseIterable {
    case province
    case city
    case event
    case individual

    var color: NSColor {
        switch self {
        case .province:
            return style.provinceColor
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
        case .province:
            return 1
        case .city:
            return 2
        case .event:
            return 3
        case .individual:
            return 4
        }
    }

    var placeholder: NSImage {
        switch self {
        case .province:
            return NSImage(named: "province-icon")!
        case .city:
            return NSImage(named: "city-icon")!
        case .event:
            return NSImage(named: "event-icon")!
        case .individual:
            return NSImage(named: "individual-icon")!
        }
    }
}
