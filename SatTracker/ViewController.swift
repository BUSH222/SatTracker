//
//  ViewController.swift
//  SatTracker
//
//  Created by Ted Vtorov on 20.07.2024.
//

import UIKit
import CoreLocation
import CoreMotion
import Foundation
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var elevationSlider: UISlider!{didSet{elevationSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))}}
    @IBOutlet weak var AzimuthSlider: UISlider!
    
    @IBOutlet weak var headingIndicator: UIImageView!
    @IBOutlet weak var rollIndicator: UIImageView!
    
    @IBOutlet weak var elevationLabel: UILabel!
    @IBOutlet weak var azimuthLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    
    var lm: CLLocationManager!
    var mm: CMMotionManager!
    var captureSession: AVCaptureSession!
    
    let threshold = 10  // deg
    
    var attitude: CMAttitude?
    var pitch = 0
    var yaw = 0
    var roll = 0
    var heading = 0
    
    var targetElevation = 20
    var targetAzimuth = 0
    
    var passData: [Array<Int>] = []
    var passDataLoaded: Bool = false
    var aos = 0
    var los = 0
    
    var timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("loaded")
        
        self.rollIndicator.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimestampLabel), userInfo: nil, repeats: true)
        
        lm = CLLocationManager()
        mm = CMMotionManager()
        mm.deviceMotionUpdateInterval = 0.1
        lm.delegate = self
        lm.startUpdatingHeading()
        updateDeviceMotions()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // helper functions
    
    func degToRad(_ number: Double) -> CGFloat {
        return CGFloat(number * Double.pi / 180)
    }
    
    func radToDeg(radians: Double) -> Double {
        return 180 / Double.pi * radians
    }
    
    func getHeadingDifference(h1: Int, h2: Int) -> Int{
        let h = h1 - h2
        if h > 180{
            return h-360
        } else if h <= -180{
            return h+360
        } else{
            return h
        }
        
    }
    
    func timestampToDate(timestamp: Int) -> String{
        let h: Int = (timestamp % 86400) / 3600
        let m: Int = (timestamp % 3600) / 60
        let s: Int = timestamp % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
        
    }
    
    // Pitch, Yaw, Roll, Compass heading
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = Int(round(Double(newHeading.magneticHeading)))
        headingIndicator.transform = CGAffineTransform(rotationAngle: degToRad(-newHeading.magneticHeading))
    }

    func checkPitch(deviceMotion:CMDeviceMotion) {
        attitude = deviceMotion.attitude
        roll = Int(round(radToDeg(radians: attitude!.roll)))
        yaw = Int(round(radToDeg(radians: attitude!.yaw)))
        pitch = Int(round(radToDeg(radians: attitude!.pitch)))
        // print("Roll: \(roll) Pitch: \(pitch) Yaw: \(yaw)")
        // print("Heading: \(heading) Diff:\(heading+yaw)")
        // pitch -90 to 90
        // yaw -180 to 180  always starts at 0, dont use, use the compass
        // roll -180 to 180
        elevationLabel.text = "Elevation:\nTarget: \(targetElevation)\nActual: \(pitch)"
        azimuthLabel.text = "Azimuth:\nTarget: \(targetAzimuth)\nActual: \(heading)"
        
        rollIndicator.transform = CGAffineTransform(rotationAngle: attitude!.roll)
        if (pitch-targetElevation > threshold) {
            elevationSlider.setValue(Float(threshold), animated: true)
        } else if (pitch-targetElevation < -threshold){
            elevationSlider.setValue(-Float(threshold), animated: true)
        } else {
            elevationSlider.setValue(Float(pitch-targetElevation), animated: true)
        }
        
        let hd = getHeadingDifference(h1: heading, h2: targetAzimuth)
        // print(hd)
        if (hd > threshold) {
            AzimuthSlider.setValue(Float(threshold), animated: true)
        } else if (hd < -threshold){
            AzimuthSlider.setValue(-Float(threshold), animated: true)
        } else {
            AzimuthSlider.setValue(Float(hd), animated: true)
        }
    }
                
     func updateDeviceMotions() {
         mm.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {
             (deviceMotion, error) -> Void in
                if(error == nil) {
                    self.checkPitch(deviceMotion: deviceMotion!)
                }
         })
     }
    

    @IBAction func scanQR(_ sender: UIButton) {
    }
    
    // timer updates
    
    @objc func updateTimestampLabel(){
        let currentTimestamp = Int(Date().timeIntervalSince1970) + Int(TimeZone.current.secondsFromGMT())
        timestampLabel.text = "AOS:   \(timestampToDate(timestamp: aos))\nLOS:    \(timestampToDate(timestamp: los))\nLT:        \(timestampToDate(timestamp: currentTimestamp))"
        print(passDataLoaded)
    }
}

