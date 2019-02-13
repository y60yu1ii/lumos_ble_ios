//
// Created by yaoyu on 2019-02-11.
//

import Foundation
import CoreBluetooth

open class PeriObj :NSObject{
    var cbPeripheral:CBPeripheral? = nil
    var key:String  = "key"
    var name:String = "name"
    var uuid:String = "uuid"
    public var connectingLock = false
    var isConnected = false
    var markDelete = false
    var controller: GattController? = nil
    var delegate: PeriObjDelegate? = nil
    var isAuthSuccess : Bool = false{ didSet { dealWithAuthState(isAuthSuccess) } }
    open func dealWithAuthState(_ isSuccess:Bool){}

    var rssi:Int = 0{
        didSet{
            if(rssi<0){
                delegate?.onRSSIChanged(rssi: rssi, periObj: self)
            }
        }
    }

    public init(_ uuid :String){
        self.uuid = uuid
    }

    deinit {
        delegate = nil
        controller = nil
    }

    func setAvl(_ avl:AvailObj){
        self.rssi = avl.rssi
        self.uuid = avl.uuid
        self.name = avl.name
    }

    func connect(peri:CBPeripheral){
        connectingLock = true
        self.cbPeripheral = peri
        name = cbPeripheral?.name ?? name
        controller = GattController(peri)
        controller?.delegate = self
        controller?.startDiscoverServices()
    }

    open func setUp(){
        connectingLock = false
        controller?.cbPeripheral.readRSSI()
    }

    open func disconnect(completion:@escaping (_:Bool)->()){}
    open func getUpdated(_ uuidStr: String, _ value: Data, _ kind: UpdateKind) {}
    open func writeWithResponse(_ uuidStr:String, data:Data){
        controller?.writeTo(uuidStr, data: data, resp: true)
    }
    open func writeTo(_ uuidStr:String, data:Data){
        controller?.writeTo(uuidStr, data: data, resp: false)
    }
}

extension PeriObj :ControllerDelegate{
    func didDiscoverServices() {
       setUp()
    }

    func onRSSIUpdated(rssi: Int) {
        self.rssi = rssi
        delegate?.onRSSIChanged(rssi: rssi, periObj: self)
    }

    func onUpdated(uuidStr: String, value: Data, kind: UpdateKind) {
        getUpdated(uuidStr, value, kind)
    }
}

protocol PeriObjDelegate{
    func onRSSIChanged(rssi: Int, periObj:PeriObj)
    func onUpdated(label: String, value:Any, periObj:PeriObj)
}
