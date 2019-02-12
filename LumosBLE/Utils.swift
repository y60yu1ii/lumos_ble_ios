//
// Created by yaoyu on 2019-02-12.
// Copyright (c) 2019 fishare. All rights reserved.
//

import Foundation

//self definition for LeVise product
func getMac(_ bytes:Data) -> String? {
    if(bytes.count > 5) {
        return String(format: "%02x:%02x:%02x:%02x:%02x:%02x", bytes[5], bytes[4], bytes[3], bytes[2], bytes[1], bytes[0]).uppercased()
    }
    return nil
}

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