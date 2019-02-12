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
    func getCustomObj(mac:String, name:String) -> PeriObj
    func getCustomAvl(peri:CBPeripheral, mac:String) -> AvailObj
}

public class CentralManager: NSObject{
    //singleton pattern
    private static let sharedInstance = CentralManager()
    static private var shInstance : CentralManager { return sharedInstance }
    @objc public static func instance() -> CentralManager { return shInstance }

//    let RECONNECT_FILTER:Int = -75//for buddy tag testing, no connection
//    let CONNECT_FILTER:Int = -48
//    let IGNORE_FILTER:Int  = -65

    var centralMgr: CBCentralManager!

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

    func postBroadcast(_ tag:String){
        NotificationCenter.default.post(name: Notification.Name(tag), object: nil, userInfo: nil)
    }
    

}

extension CentralManager : CBCentralManagerDelegate{
    /**
     *  on Scanned results
     *
     **/
    private func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        
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


