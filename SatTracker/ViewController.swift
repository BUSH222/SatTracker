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

class ViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var elevationSlider: UISlider!{didSet{elevationSlider.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))}}
    @IBOutlet weak var AzimuthSlider: UISlider!
    
    @IBOutlet weak var headingIndicator: UIImageView!
    @IBOutlet weak var rollIndicator: UIImageView!
    
    @IBOutlet weak var elevationLabel: UILabel!
    @IBOutlet weak var azimuthLabel: UILabel!
    
    
    var lm: CLLocationManager!
    var mm: CMMotionManager!
    
    var attitude: CMAttitude?
    var pitch = 0
    var yaw = 0
    var roll = 0
    
    var heading = 0
    
    var targetElevation = 20
    var targetAzimuth = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("loaded")
        
        self.rollIndicator.anchorPoint = CGPoint(x: 0.5, y: 1)
        
        // let threshold = 10  // deg
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
    
    // Pitch, Yaw, Roll, Compass heading
    
    func degToRad(_ number: Double) -> CGFloat {
        return CGFloat(number * Double.pi / 180)
    }
    
    func radToDeg(radians: Double) -> Double {
        return 180 / Double.pi * radians
    }
    
    func getHeadingDifference(h1: Int, h2: Int) -> Int{
        var h = h1 - h2
        if h > 180{
            return h-360
        } else if h <= -180{
            return h+360
        } else{
            return h
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = Int(round(Double(newHeading.magneticHeading)))
        headingIndicator.transform = CGAffineTransform(rotationAngle: degToRad(-newHeading.magneticHeading))
    }

    func checkPitch(deviceMotion:CMDeviceMotion) {
        attitude = deviceMotion.attitude
        roll = Int(round(radToDeg(radians: attitude!.roll)))
        yaw = Int(round(radToDeg(radians: attitude!.yaw)))
        pitch = Int(round(radToDeg(radians: attitude!.pitch)))
        //print("Roll: \(roll) Pitch: \(pitch) Yaw: \(yaw)")
        //print("Heading: \(heading) Diff:\(heading+yaw)")
        // pitch -90 to 90
        // yaw -180 to 180  always starts at 0, dont use, use the compass
        // roll -180 to 180
        elevationLabel.text = "Elevation:\nTarget: \(targetElevation)\nActual: \(pitch)"
        azimuthLabel.text = "Azimuth:\nTarget: \(targetAzimuth)\nActual: \(heading)"
        
        rollIndicator.transform = CGAffineTransform(rotationAngle: attitude!.roll)
        if (pitch-targetElevation > 10) {
            elevationSlider.setValue(10, animated: true)
        } else if (pitch-targetElevation < -10){
            elevationSlider.setValue(-10, animated: true)
        } else {
            elevationSlider.setValue(Float(pitch-targetElevation), animated: true)
        }
        
        let hd = getHeadingDifference(h1: heading, h2: targetAzimuth)
        print(hd)
        if (hd > 10) {
            AzimuthSlider.setValue(10, animated: true)
        } else if (hd < -10){
            AzimuthSlider.setValue(-10, animated: true)
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


}

