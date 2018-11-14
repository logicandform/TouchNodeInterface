//  Copyright © 2018 JABT. All rights reserved.

import Foundation


typealias RelatedLevels = [Set<Record>]


final class RecordManager {
    static let instance = RecordManager()

    private(set) var relatedLevelsForRecord = [Record: RelatedLevels]()
    private(set) var recordsForType: [RecordType: [Int: Record]] = [:]


    // MARK: Init

    /// Use singleton
    private init() {
        for type in RecordType.allCases {
            recordsForType[type] = [:]
        }
    }


    // MARK: API

    func initialize() {
        guard let jsonURL = Bundle.main.url(forResource: "cities", withExtension: "json"), let data = try? Data(contentsOf: jsonURL), let jsonData = try? JSONSerialization .jsonObject(with: data, options: []) as? [JSON], let json = jsonData else {
            fatalError("Failed to serialize City records from cities.json file.")
        }

        // Create records
        let provinces = Set(json.compactMap { Province(json: $0) })
        let cities = Set(json.compactMap { City(json: $0) })
        let eventIDs = (1...30)
        let events = Set(eventIDs.map { Record(type: .event, id: $0, title: "Event \($0)", description: "Description of event \($0)") })
        let records = [provinces, cities, events].reduce([], +)

        // Cache records by type and id
        for record in records {
            recordsForType[record.type]?[record.id] = record
        }

        // Create relationships
        for city in cities {
            // Relate to province
            if let province = provinces.first(where: { $0.title == city.province }) {
                province.relate(to: city)
                city.relate(to: province)
            }
            // Relate to random events
            let relatedEventIDs = (1...10).map { _ in Int.random(in: eventIDs) }
            let relatedEvents = relatedEventIDs.compactMap { recordsForType[.event]?[$0] }
            for event in relatedEvents {
                event.relate(to: city)
                city.relate(to: event)
            }
        }

        // Create levels for each record
        createLevelsForRecords()

        // Create entities for each record
        for (record, levels) in relatedLevelsForRecord {
            if let record = RecordManager.instance.recordsForType[record.type]?[record.id] {
                EntityManager.instance.createEntity(record: record, levels: levels)
            }
        }
    }


    // MARK: Helpers

    /// Returns a set of records from the given ids
    private func records(for type: RecordType, ids: [Int]) -> Set<Record> {
        return Set(ids.compactMap { recordsForType[type]?[$0] })
    }

    private func records(for type: RecordType) -> [Record] {
        guard let recordsForID = recordsForType[type] else {
            return []
        }

        return Array(recordsForID.values)
    }

    private func createLevelsForRecords() {
        let allRecords = RecordType.allCases.reduce([]) { $0 + records(for: $1) }

        for record in allRecords {
            // Populate level 0
            let relatives = Set(record.relatedRecords())
            var levelsForRecord = RelatedLevels()
            levelsForRecord.insert(relatives, at: 0)

            // Populate following levels based on the level 0 entities
            for level in (1 ..< NodeCluster.maxRelatedLevels) {
                let recordsForPreviousLevel = levelsForRecord.at(index: level - 1) ?? []
                var recordsForLevel = Set<Record>()
                for each in recordsForPreviousLevel {
                    let relatedRecords = each.relatedRecords()
                    for relatedRecord in relatedRecords {
                        if !levels(levelsForRecord, contains: relatedRecord) && relatedRecord != record {
                            recordsForLevel.insert(relatedRecord)
                        }
                    }
                }
                if recordsForLevel.isEmpty {
                    break
                }
                levelsForRecord.insert(recordsForLevel, at: level)
            }
            relatedLevelsForRecord[record] = levelsForRecord
        }
    }

    private func levels(_ levels: RelatedLevels, contains record: Record) -> Bool {
        for level in levels {
            if level.contains(record) {
                return true
            }
        }
        return false
    }
}
