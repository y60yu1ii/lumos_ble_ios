//
// Created by yaoyu on 2019-02-12.
// Copyright (c) 2019 fishare. All rights reserved.
//

import Foundation
let REFRESH_ALL = "de.fishare.refresh"
let CONNECTION  = "de.fishare.connection"
let BLUETOOTH_STATE = "de.fishare.bluetooth.state"



func matches(for regex: String, in text: String) -> [String] {
    do {
        let regex = try NSRegularExpression(pattern: regex)
        let results = regex.matches(in: text,
                range: NSRange(text.startIndex..., in: text))
        return results.map {
            String(text[Range($0.range, in: text)!])
        }
    } catch let error {
        print("invalid regex: \(error.localizedDescription)")
        return []
    }
}