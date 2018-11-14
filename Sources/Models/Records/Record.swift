//  Copyright © 2018 JABT. All rights reserved.

import Foundation
import MapKit


class Record: Hashable {

    let type: RecordType
    let id: Int
    let title: String
    let description: String
    let dates: DateRange?
    var coordinate: CLLocationCoordinate2D?
    var relatedRecordsForType = [RecordType: Set<Record>]()

    var relatedRecords: [Record] {
        return relatedRecordsForType.values.reduce([], +).sorted { lhs, rhs in
            if lhs.type.sortOrder == rhs.type.sortOrder {
                return lhs.id < rhs.id
            }
            return lhs.type.sortOrder < rhs.type.sortOrder
        }
    }

    var hashValue: Int {
        return id.hashValue ^ type.hashValue
    }


    // MARK: Init

    init(type: RecordType, id: Int, title: String, description: String, dates: DateRange?, coordinate: CLLocationCoordinate2D?) {
        self.type = type
        self.id = id
        self.title = title
        self.description = description
        self.dates = dates
        self.coordinate = coordinate
    }


    // MARK: API

    func relate(to record: Record) {
        if let siblings = relatedRecordsForType[record.type] {
            relatedRecordsForType[record.type] = siblings.union([record])
        } else {
            relatedRecordsForType[record.type] = [record]
        }
    }


    // MARK: Hashable

    static func == (lhs: Record, rhs: Record) -> Bool {
        return lhs.id == rhs.id && lhs.type == rhs.type && lhs.title == rhs.title
    }
}
