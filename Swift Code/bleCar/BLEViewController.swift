//
//  BLEViewController.swift
//  bleCar
//
//  Created by ilker on 11/04/15.
//  Copyright (c) 2015 isikun. All rights reserved.
//

import UIKit

class BLEViewController: UIViewController {
    
    @IBOutlet weak var encoderTxt: UITextField!
    @IBOutlet var panCoord: UIPanGestureRecognizer!
    @IBOutlet weak var waitingBar: UIActivityIndicatorView!
    @IBOutlet weak var waitingLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var compassLabel: UILabel!
    @IBOutlet weak var compassText: UITextField!
    @IBOutlet weak var rightEncoder: UILabel!
    @IBOutlet weak var leftEncoder: UILabel!
    var timerTXDelay: NSTimer?
    var allowTX = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        waitingBar.startAnimating()
        // Watch Bluetooth connection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("connectionChanged:"), name: BLEServiceChangedStatusNotification, object: nil)
        btDiscoverySharedInstance //initiate bluetooth
        // Do any additional setup after loading the view.
        slider.transform = CGAffineTransformRotate(slider.transform , (1.5 * 3.14));
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    @IBAction func writeEncoder(sender: UIButton) {
        if !self.allowTX {
            return
        }
        var command : String = "ENC \(self.encoderTxt.text) x"
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeStringCommand(command: command)
            self.allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("timerTXDelayElapsed"), userInfo: nil, repeats: false)
            }
        }

    }
    @IBAction func sliderChanged(sender: UISlider) {
        if !self.allowTX {
            return
        }
        let sliderValue = Int(sender.value)
        var forwardOrReverse = sliderValue>50 ? 0 : 1
        var command : String = "MDA \(forwardOrReverse)x"//MDA means Motors all
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeStringCommand(command: command)
            self.allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("timerTXDelayElapsed"), userInfo: nil, repeats: false)
            }
        }

    }
    
    @IBAction func sendCompass(sender: AnyObject) {
        if !self.allowTX {
            return
        }
        var command : String = "COM \(self.compassLabel.text) x"
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeStringCommand(command: command)
            self.allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("timerTXDelayElapsed"), userInfo: nil, repeats: false)
            }
        }

    }

    func timerTXDelayElapsed() {
        self.allowTX = true
        self.stopTimerTXDelay()
    }
    
    func stopTimerTXDelay() {
        if self.timerTXDelay == nil {
            return
        }
        
        timerTXDelay?.invalidate()
        self.timerTXDelay = nil
    }

    
     func connectionChanged(notification: NSNotification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = notification.userInfo as! [String: AnyObject]
        
        dispatch_async(dispatch_get_main_queue(), {
            // Set image based on connection status
            if let isConnected = userInfo["isConnected"] as? Bool{
                if isConnected {
                    self.waitingBar.stopAnimating()
                    self.waitingLabel.text = "Connected"
                } else {
                    self.waitingBar.startAnimating()
                    self.waitingLabel.text = "Searching..."
                }
            }
            if let compassInfo = userInfo["compassInfo"] as? Float{
                self.compassLabel.text? = "Compass : \(compassInfo)"
            }
            if let encoderInfo = userInfo["encoderInfo"] as? [Int]{
                self.leftEncoder.text? = "Left : \(encoderInfo[0])"
                self.rightEncoder.text? = "Right : \(encoderInfo[1])"
            }
        });
    }
    var speed : Int{
        get{
            let value = Int(slider.value)
            if(value <= 50){
                return value * 2
            }
            return value
        }
    }
    
    var degree : CGFloat = 0.0{
        didSet{
            degreeDidSet(degree)
        }
    }
    
    @IBAction func breakDidPressed(sender: AnyObject) {
        if !self.allowTX {
            return
        }
        let command = "BALL 0x"
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeStringCommand(command: command)
            self.allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("timerTXDelayElapsed"), userInfo: nil, repeats: false)
            }
        }

    }
    func degreeDidSet(degree : CGFloat){
        if !self.allowTX {
            return
        }
        let degreeAsInt = Int(degree)
        var command : String?
        //println(degreeAsInt)
        if(degreeAsInt >= -5 && degreeAsInt < 5){
            command = "MSA \(speed + 155)x"
        }else if(degreeAsInt < -40){
            command = "MS2 \(speed + 155)x"
        }else if(degreeAsInt > 40){
            command = "MS1 \(speed + 155)x"
        }else{
            var leftValue : Int
            var rightValue : Int
            if(degreeAsInt>0){
                rightValue = degreeAsInt + speed + 90
                leftValue = (-degreeAsInt) + speed + 115
            }else{
                rightValue = (-degreeAsInt)  + speed + 115
                leftValue = degreeAsInt + speed + 90
            }
            command = "MSA \(leftValue) \(rightValue)x"
        }
        
        if let bleService = btDiscoverySharedInstance.bleService {
            bleService.writeStringCommand(command: command!)
            self.allowTX = false
            if timerTXDelay == nil {
                timerTXDelay = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("timerTXDelayElapsed"), userInfo: nil, repeats: false)
            }
        }
    }
    
    @IBAction func rotateWheel(rotationGR:UIRotationGestureRecognizer){
        let radians = atan2(rotationGR.view!.transform.b, rotationGR.view!.transform.a)
        degree = radians * (180 / CGFloat(M_PI))
        if(degree > -50 && degree < 50){
            let rotation = rotationGR.rotation
            let transform = CGAffineTransformRotate(rotationGR.view!.transform, rotation)
            rotationGR.view!.transform = transform
        }else{
            let rotation = CGFloat(0.1 * ((degree < -50) ? 1 : -1))
            let transform = CGAffineTransformRotate(rotationGR.view!.transform, rotation)
            rotationGR.view!.transform = transform
        }
        if(rotationGR.state == UIGestureRecognizerState.Ended){
            //let rotation = CGFloat(0.5)
            UIView.animateWithDuration(0.5, animations: {
                rotationGR.view!.transform = CGAffineTransformMakeRotation(0)
            })
        }
        rotationGR.rotation = 0
        
    }
}
