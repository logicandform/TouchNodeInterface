//  Copyright © 2018 JABT. All rights reserved.

import Foundation


final class Province: Record {
    static private var counter = 0

    private struct Keys {
        static let title = "admin"
    }


    // MARK: Init

    init?(json: JSON) {
        guard let title = json[Keys.title] as? String else {
            return nil
        }

        super.init(type: .province, id: title.hashValue, title: title, description: title)
    }
}
