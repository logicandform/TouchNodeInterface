//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class City: Record {
    static private var counter = 0

    private struct Keys {
        static let title = "city"
        static let population = "population"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let title = json[Keys.title] as? String, let population = json[Keys.population] as? String else {
            return nil
        }

        City.counter += 1
        let description = "\(title) has a population of \(population)."
        super.init(type: .city, id: City.counter, title: title, description: description, dates: nil, coordinate: nil)
    }
}
