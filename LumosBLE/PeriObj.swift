//
// Created by yaoyu on 2019-02-11.
//

import Foundation
import CoreBluetooth

open class PeriObj :NSObject{
    public var cbPeripheral:CBPeripheral? = nil
    public var key:String  = "key"
    public var name:String = "name"
    public var uuid:String = "uuid"
    public var connectingLock = false
    public var isConnected = false
    public var markDelete = false
    public var delegate: PeriObjDelegate? = nil
    public var isAuthSuccess : Bool = false{ didSet { dealWithAuthState(isAuthSuccess) } }
    open func dealWithAuthState(_ isSuccess:Bool){}
    var controller: GattController? = nil
    public var rssi:Int = 0{
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
        self.cbPeripheral = avl.cbPeripheral
        self.key  = avl.key
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
        DispatchQueue.main.async{
            self.controller?.startDiscoverServices()
        }
    }

    open func setUp(){
        connectingLock = false
        controller?.cbPeripheral.readRSSI()
    }

    open func disconnect(completion:@escaping (_:Bool)->()){}
    open func getUpdated(_ uuidStr: String, _ value: Data, _ kind: UpdateKind) {}

    public func writeTo(_ uuidStr:String, data:Data){
        controller?.writeTo(uuidStr, data: data, resp: true)
    }
    public func writeToNoResp(_ uuidStr:String, data:Data){
        controller?.writeTo(uuidStr, data: data, resp: false)
    }
}

extension PeriObj :ControllerDelegate{
    func didDiscoverServices() {
        print("didDiscover services ")
        print("\(controller?.charaDict.keys) ")
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

public protocol PeriObjDelegate{
    func onRSSIChanged(rssi: Int, periObj:PeriObj)
    func onUpdated(label: String, value:Any, periObj:PeriObj)
}
