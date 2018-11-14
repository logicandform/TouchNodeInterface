//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class RecordManager {
    static let instance = RecordManager()

    /// Type: [ID: Record]
    private var recordsForType: [RecordType: [Int: Record]] = [:]


    // MARK: Init

    /// Use singleton
    private init() {
        for type in RecordType.allCases {
            recordsForType[type] = [:]
        }
    }


    // MARK: API

    /// Creates mock records and relates them to one another
    func initialize() {
        guard let jsonURL = Bundle.main.url(forResource: "cities", withExtension: "json"), let data = try? Data(contentsOf: jsonURL), let json = try? JSONSerialization .jsonObject(with: data, options: []) as? [JSON], let citiesJSON = json else {
            fatalError("Failed to serialize City records from cities.json file.")
        }

        let cities = citiesJSON.compactMap { City(json: $0) }
        store(cities, for: .city)

        // Create events and individuals to relate to each city
        var siblings = [Record]()
        for id in (1 ... 10) {
            siblings.append(Record(type: .event, id: id, title: "Event \(id)", description: "Description", dates: nil, coordinate: nil))
            siblings.append(Record(type: .individual, id: id, title: "Person \(id)", description: "Description", dates: nil, coordinate: nil))
        }

        for city in cities {
            for sibling in siblings {
                city.relate(to: sibling)
            }
        }
    }

    func allRecords() -> [Record] {
        return RecordType.allCases.reduce([]) { $0 + records(for: $1) }
    }

    func record(for type: RecordType, id: Int) -> Record? {
        return recordsForType[type]?[id]
    }

    func records(for type: RecordType, ids: [Int]) -> [Record] {
        return ids.compactMap { recordsForType[type]?[$0] }
    }

    func records(for type: RecordType) -> [Record] {
        guard let recordsForID = recordsForType[type] else {
            return []
        }

        return Array(recordsForID.values)
    }


    // MARK: Helpers

    private func createRecords(of type: RecordType) -> [Record] {
        return []
    }

    private func store(_ records: [Record], for type: RecordType) {
        for record in records {
            recordsForType[type]?[record.id] = record
        }
    }
}
