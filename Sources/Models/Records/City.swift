//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class City: Record {

    let province: String

    private struct Keys {
        static let title = "city"
        static let population = "population"
        static let province = "admin"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let title = json[Keys.title] as? String, let population = json[Keys.population] as? String, let province = json[Keys.province] as? String else {
            return nil
        }

        self.province = province
        let description = "\(title) has a population of \(population)."
        super.init(type: .city, id: title.hashValue, title: title, description: description, dates: nil, coordinate: nil)
    }
}
