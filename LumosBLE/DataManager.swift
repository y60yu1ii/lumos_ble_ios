//
// Created by yaoyu on 2019-02-12.
// Copyright (c) 2019 fishare. All rights reserved.
//

import Foundation
let ud = UserDefaults.standard

func getHistory() -> Array<String> {
    return ud.array(forKey: "history") as? Array<String> ?? []
}

func setHistory(list:Array<String>){
    ud.set(list, forKey: "history")
    ud.synchronize()
}

func addToHistory(_ key:String){
    if var ls = ud.array(forKey: "history") as? [String] {
        if !ls.contains(key) {
            ls.append(key)
            setHistory(list: ls)
        }
    }else {
        setHistory(list: [key])
    }
}

func delFromHistory(_ key:String){
    if var ls =  ud.array(forKey: "history") as? [String]{
        ls = ls.filter{$0 != key}
        ud.set(ls, forKey: "history")
        ud.synchronize()
    }
}