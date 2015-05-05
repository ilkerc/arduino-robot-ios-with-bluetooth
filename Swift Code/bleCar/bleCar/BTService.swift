//
//  BTService.swift
//  Arduino_Servo
//
//  Created by Owen L Brown on 10/11/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

import Foundation
import CoreBluetooth

/* Services & Characteristics UUIDs */
let BLEServiceUUID = CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
let PositionCharUUID = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTService: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral?
    var positionCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral?.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: - CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        let uuidsForBTService: [CBUUID] = [PositionCharUUID]
        
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        if ((peripheral.services == nil) || (peripheral.services.count == 0)) {
            // No Services
            return
        }
        
        for service in peripheral.services {
            println(service.UUIDString)
            if service.UUID == BLEServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as! CBService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        for characteristic in service.characteristics {
            if characteristic.UUID == PositionCharUUID {
                self.positionCharacteristic = (characteristic as! CBCharacteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as! CBCharacteristic)
                
                // Send notification that Bluetooth is connected and all required characteristics are discovered
                self.sendBTServiceNotificationWithIsBluetoothConnected(true)
            }
        }
    }
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if ((error) != nil) {
            println("Error reading characteristics: \(error.localizedDescription)")
            return
        }
        
        if (characteristic.value != nil) {
            let bytes = NSString(bytes: characteristic.value.bytes, length: characteristic.value.length, encoding: 1)
            if (bytes! as NSString).containsString("COM"){
                let length = bytes?.rangeOfString("COM")
                let f = bytes!.substringFromIndex(length!.toRange()!.endIndex)
                self.sendCompassNotification((f as NSString).floatValue)
                
            }
            if (bytes! as NSString).hasPrefix("L"){
                let length2 = bytes?.rangeOfString("L")
                let numbersLandR = bytes!.substringFromIndex(length2!.toRange()!.endIndex)
                let leftAndRightArray = split(numbersLandR){$0 == " "}
                self.sendEncoderNotification([(leftAndRightArray[0] as NSString).integerValue, (leftAndRightArray[2] as NSString).integerValue])
                
            }
        }
        
    }
    
    // Mark: - Private
    func writeStringCommand(#command: String){
        if self.positionCharacteristic == nil {
            return
        }
        let data = command.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        self.peripheral?.writeValue(data, forCharacteristic: self.positionCharacteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }
    
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
    func sendCompassNotification(compasData : Float){
        let compass = ["compassInfo": compasData]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: compass)
    }
    
    func sendEncoderNotification(encoderInfo : [Int]){
        let encoder = ["encoderInfo": encoderInfo]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: encoder)
    }
    
}