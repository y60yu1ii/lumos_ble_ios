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

    let CONNECT_FILTER:Int = -75
    let REGX_ALL = ".*?"

    public var serviceUUIDs = [String]()
    var avails = [AvailObj]()
    var periMap = [String:PeriObj]()
    var peris : [PeriObj] { get{ return periMap.map{$0.1} } }

    var centralMgr: CBCentralManager!
    var setting : Setting? = nil
    var event : EventListener? = nil

    private override init(){
        super.init()
        centralMgr = CBCentralManager(delegate: self, queue: DispatchQueue.global(qos: .background), options: [CBCentralManagerOptionShowPowerAlertKey:true])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}

extension CentralManager{

    @objc public func startAPP(){
        //prevent from doing nothing when initiated
        print("Open central manager \u{24}")
    }

    @objc public func connect(_ mac:String){
        let avl = avails.first{ $0.mac == mac }
        if(avl != nil){ connect(avl!) }
    }

    @objc public func disconnect(_ mac:String){
        let peri = periMap[mac]
        if(peri != nil){
           disconnect(peri!, isRemove: false)
        }
    }

    @objc public func remove(_ mac:String){
        let peri = periMap[mac]
        if(peri != nil){
            disconnect(peri!, isRemove: true)
        }
    }

    @objc public func loadHistory(){
        getHistory().forEach{
            let name:String = loadProfile($0, "name")
            periMap[$0] = (setting?.getCustomObj($0, name) ?? PeriObj($0))
        }
    }
}

extension CentralManager : CBCentralManagerDelegate{
    /**
     *  on Scanned results
     *
     **/
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("Scan name is \(peripheral.name ?? "")")
        if !isValidName(name: peripheral.name) { return }
        let rssi = RSSI.intValue
        guard rssi != 127 else { return }
        let data = advertisementData["kCBAdvDataManufacturerData"] as? Data ?? Data()
        let key = getMac(data) ?? peripheral.identifier.uuidString
        let peri = periMap[key]
        if(peri != nil && !(peri?.markDelete == true)){
            connect(makeAvail(peripheral, rawData: data))
            return
        }

        let avl = avails.first{ $0.mac == key }
        if(avl != nil){
            avl!.rssi = rssi
            avl!.rawData = data
        }else if(rssi > CONNECT_FILTER){
            let a = makeAvail(peripheral, rawData: data)
            avails.append(a)
            event?.didDiscover(a)
            print("[ADD to AVAIL] count is \(avails.count) mac is \(a.mac)")
        }
    }

    func isValidName(name:String?) -> Bool{
        guard let n = name else{ return false }
        let matched = matches(for: setting?.getNameRule() ?? REGX_ALL, in: n)
        return !matched.isEmpty
    }

    func makeAvail(_ peri:CBPeripheral, rawData:Data) -> AvailObj{
        let key = getMac(rawData) ?? peri.identifier.uuidString
        let avl:AvailObj = setting?.getCustomAvl(peri) ?? AvailObj(peri)
        avl.rawData = rawData
        avl.mac = key
        avl.uuid = peri.identifier.uuidString
        return avl
    }

    //did connect callback
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[CONNECTED] \(peripheral.name ?? "") is connected")
        let uuid = peripheral.identifier.uuidString
        let periObj = peris.first{ $0.uuid == uuid }
        if(periObj != nil){
            print("[CONNECTED] \(periObj!.name) with \(periObj!.mac) and UUID \(periObj!.uuid)")
            DispatchQueue.main.async {
                periObj!.connect(peri: peripheral)
            }
            NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["mac" : periObj!.mac, "connected": true])
        }
    }

    //did disconnect callback
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("[DISCONNECTED] \(peripheral.name ?? "") is dropped uuid is \( peripheral.identifier.uuidString )")
        let uuid = peripheral.identifier.uuidString
        let periObj = peris.first{ $0.uuid == uuid }
        if(periObj != nil) {
            periObj?.cbPeripheral?.delegate = nil
            if (periObj!.markDelete == true || periObj!.isAuthSuccess != true) {
                periMap.removeValue(forKey: periObj!.mac)
            }
            NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["mac" : periObj!.mac, "connected": false])
        }
    }

    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[FAIL DISCONNECTED] \(peripheral.name ?? "") is dropped uuid is \( peripheral.identifier.uuidString )")
        let uuid = peripheral.identifier.uuidString
        let periObj = peris.first{ $0.uuid == uuid }
        if(periObj != nil) {
            periObj?.cbPeripheral?.delegate = nil
            if (periObj!.markDelete == true || periObj!.isAuthSuccess != true) {
                periMap.removeValue(forKey: periObj!.mac)
            }
            NotificationCenter.default.post(name: Notification.Name(CONNECTION),
                    object: nil, userInfo: ["mac" : periObj!.mac, "connected": false])
        }
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

    private func disconnect(_ periObj :PeriObj, isRemove:Bool){
        print("Disconnecting")
        periObj.markDelete = isRemove
        periObj.disconnect(){ completed in
            if(completed && periObj.cbPeripheral != nil){ self.centralMgr.cancelPeripheralConnection(periObj.cbPeripheral!)}
        }
        if(isRemove){ removeFromHistory(periObj.mac) }
    }

    private func doScan(){
        let services = serviceUUIDs.map{ (uuid)-> CBUUID in return CBUUID.init(string: uuid)}
        print("scan with 27 \(services)")
        DispatchQueue.main.async {
            self.centralMgr.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
            print("is scanning \(self.centralMgr.isScanning)")
        }
    }

    private func bluetoothIsOff(){
        peris.forEach{
            if($0.cbPeripheral != nil){ self.centralMgr.cancelPeripheralConnection($0.cbPeripheral!) }
        }
        avails.removeAll()
    }

    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if #available(iOS 10.0, *) {
            switch central.state{
            case CBManagerState.unauthorized:
                print("This app is not authorised to use Bluetooth low energy")
            case CBManagerState.poweredOff:
                print("Ble off")
                bluetoothIsOff()
            case CBManagerState.poweredOn:
                print("Ble on")
                doScan()
            default:break
            }
        } else {
            switch central.state.rawValue {
            case 3: // CBCentralManagerState.unauthorized :
                print("This app is not authorised to use Bluetooth low energy")
            case 4: // CBCentralManagerState.poweredOff:
                print("Ble off")
                bluetoothIsOff()
            case 5: //CBCentralManagerState.poweredOn:
                print("Ble on")
                doScan()

            default:break
            }
        }
    }
}

