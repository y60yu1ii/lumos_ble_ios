//
// Created by yaoyu on 2019-02-11.
//

import Foundation
import CoreBluetooth

public class AvailObj :NSObject{
    var cbPeripheral:CBPeripheral
    var name:String = "name"
    var mac:String  = "mac"
    var uuid:String
    var lastUpdateTime:Int = 0
    var rawData:Data = Data(){ didSet{ onRawUpdate(rawData) }}
    open func onRawUpdate(_ data: Data){}
    var rssi:Int = 0{
        didSet{
            if(rssi<0){
                delegate?.onRSSIChanged(rssi: rssi, availObj: self)
                lastUpdateTime = Int(Date().timeIntervalSince1970)
            }
        }
    }

    var delegate:AvailObjDelegate? = nil
    init(peri: CBPeripheral){
        cbPeripheral = peri
        uuid = peri.identifier.uuidString
        name = peri.name ?? "name"
    }
    deinit {
        delegate = nil
    }

}

protocol AvailObjDelegate{
    func onRSSIChanged(rssi: Int, availObj:AvailObj)
    func onUpdated(label: String, value:Any, availObj:AvailObj)
}