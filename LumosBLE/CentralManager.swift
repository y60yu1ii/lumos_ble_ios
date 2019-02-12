//
// Created by yaoyu on 2018/7/11.
// Copyright (c) 2018 Facebook. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol EventListener {
    func didDiscover(_ availObj:AvailObj)
}

protocol Setting{
    func getNameRule() -> String
    func getCustomObj(_ key:String, _ name:String) -> PeriObj
    func getCustomAvl(_ peri:CBPeripheral) -> AvailObj
}

public class CentralManager: NSObject{
    //singleton pattern
    private static let sharedInstance = CentralManager()
    static private var shInstance : CentralManager { return sharedInstance }
    @objc public static func instance() -> CentralManager { return shInstance }

//    let RECONNECT_FILTER:Int = -75//for buddy tag testing, no connection
//    let CONNECT_FILTER:Int = -48
//    let IGNORE_FILTER:Int  = -65
    let REGX_ALL = ".*?"

    var avails = [AvailObj]()
    var periMap = [String:PeriObj]()
    var peris : [PeriObj] { get{ return periMap.map{$0.1} } }

    var centralMgr: CBCentralManager!
    var setting : Setting? = nil

    private override init(){
        super.init()
        centralMgr = CBCentralManager(delegate: self,
                                      queue: DispatchQueue.global(), options: [CBCentralManagerOptionShowPowerAlertKey:false])
    }

    @objc public func startAPP(){
        //prevent from doing nothing when initiated
        print("Open central manager \u{24}")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadHistory(){
        //        getHistory().forEach{ if($0 != ""){ deviceMap[$0] = JoeyDevice($0) }}
      
    }

    func postBroadcast(_ label:String){
    }

}

extension CentralManager : CBCentralManagerDelegate{
    /**
     *  on Scanned results
     *
     **/
    private func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if !isValidName(name: peripheral.name) { return }
        guard RSSI.intValue != 127 else { return }
        let data = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
        let key = getMac(data) ?? peripheral.identifier.uuidString
        let peri = periMap[key]
        if(peri != nil && !(peri?.markDelete == true)){
            let avl = setting?.getCustomAvl(peripheral) ?? AvailObj(peripheral)
            avl.rawData = data
            avl.mac = key
            avl.uuid = peripheral.identifier.uuidString
        }
    }

    //did connect callback
    private func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[CONNECTED] \(peripheral.name ?? "") is connected")
        let uuid = peripheral.identifier.uuidString
        let peri = peris.first{ $0.uuid == uuid }
        if(peri != nil){
            print("[CONNECTED] \(peri!.name) with \(peri!.mac) and UUID \(peri!.uuid)")
            DispatchQueue.main.async {
                peri!.connect(peri: peripheral)
            }
            NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["mac" : peri!.mac, "connected": true])
        }
    }

    //did disconnect callback
    private func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[DISCONNECTED] \(peripheral.name ?? "") is dropped uuid is \( peripheral.identifier.uuidString )")
        let uuid = peripheral.identifier.uuidString
        let periObj = peris.first{ $0.uuid == uuid }
        if(periObj != nil) {
            if (periObj!.markDelete == true || periObj!.isAuthSuccess != true) {
                periMap.removeValue(forKey: periObj!.mac)
            }
            NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["mac" : peri!.mac, "connected": false])
        }
    }

    private func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[FAIL DISCONNECTED] \(peripheral.name ?? "") is dropped uuid is \( peripheral.identifier.uuidString )")
        let uuid = peripheral.identifier.uuidString
        let periObj = peris.first{ $0.uuid == uuid }
        if(periObj != nil) {
            if (periObj!.markDelete == true || periObj!.isAuthSuccess != true) {
                periMap.removeValue(forKey: periObj!.mac)
            }
            NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["mac" : peri!.mac, "connected": false])
        }
   }

    func isValidName(name:String?) -> Bool{
        guard let n = name else{ return false }
//        "(Joey|BUDDY)-[a-zA-Z0-9]{3,7}"
        let matched = matches(for: setting?.getNameRule() ?? REGX_ALL, in: n)
        return !matched.isEmpty
    }

    func addAvail(){

    }

    private func connect(_ avl:AvailObj){
        print("[CentralManager] Connecting")
        let periObj:PeriObj = periMap[avl.mac] ?? setting?.getCustomObj(avl.mac, avl.name) ?? PeriObj(avl.mac)
        if(!periObj.connectingLock ){
            periObj.setAvl(avl)
            DispatchQueue.main.async{
                self.centralMgr.connect(avl.cbPeripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true])
            }
            avl.delegate = nil
            avails.removeAll { $0.mac == avl.mac }
            addToHistory(avl.mac)
            saveProfile(avl.mac, "name", avl.name)
        }
    }

    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch central.state{
            case CBManagerState.unauthorized:
                print("This app is not authorised to use Bluetooth low energy")
            case CBManagerState.poweredOff:
                print("Ble off")

            case CBManagerState.poweredOn:
                print("Ble on")

            default:break
            }
        } else {
            switch central.state.rawValue {
            case 3: // CBCentralManagerState.unauthorized :
                print("This app is not authorised to use Bluetooth low energy")
            case 4: // CBCentralManagerState.poweredOff:
                print("Ble off")

            case 5: //CBCentralManagerState.poweredOn:
                print("Ble on")

            default:break
            }
        }
    }
}

