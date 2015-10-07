//
//  ViewController.swift
//  AFTV-Test
//
//  Created by Michael Main on 1/11/15.
//  Copyright (c) 2015 Michael Main. All rights reserved.
//

import UIKit

class ViewController: UIViewController, STOMPClientDelegate {
    var client : STOMPClient!
    var currentId :String?
    let PID : String = "IKKICON_AMV_2015"
    
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var ratingSlider: UISlider!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var thumbnailImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var adapter : STOMPClientAdapter = StarscreamAdapter(
            scheme: "ws",
            host: "localhost:8080",
            path: "/aftv-backend/v1/stomp/websocket")
        
        adapter.delegate = self
        client = STOMPClient(socket: adapter)
        
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        dispatch_async(dispatch_get_global_queue(priority, 0)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.refreshUI(self.PID)
            }
        }
    }
    
    func onConnect() {
        print("websocket is connected")
        client.connect("localhost", version: "1.2")
    }
    
    func onDisconnect(error: NSError?) {
        if let e = error {
            print("websocket is disconnected: \(e.localizedDescription)")
        }
    }
    
    func onReceive(message: String) {
        print("<<\(message)\n\n")
        let frame = STOMPFrame(stompString: message)
        
        if frame.command == STOMPCommand.CONNECTED {
            client.subscribe(getQueue())
        } else if frame.command == STOMPCommand.MESSAGE {
            if frame.headers["destination"]! == getQueue() {
                if frame.headers["content-type"]?.rangeOfString("application/json") != nil {
                    updateUI(frame.body)
                }
            }
        } else if frame.command == STOMPCommand.RECEIPT {
            
        } else if frame.command == STOMPCommand.ERROR {
            print("An error has occured: \(frame.body)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func sliderMoved(sender: UISlider) {
        let sliderValue : Int = Int(round(sender.value))
        ratingSlider.value = Float(sliderValue)
        
        ratingLabel.text = "\(sliderValue)/10"
    }
    
    @IBAction func submitVote(sender: UIButton) {
        let sliderValue : Int = Int(round(ratingSlider.value))
        vote(PID, vid: currentId!, comment: "", rating: sliderValue)
    }
    
    func vote(pid: String, vid : String, comment: String, rating : Int) {
        AFTVClient.vote(pid, vid: vid, comment: comment, rating: rating)
    }
    
    // Make a first REST call to get the initial state of the contest
    func refreshUI(pid : String) {
        ratingSlider.value = 0
        
        let entry = AFTVClient.getCurrentlyPlaying(pid)
        let href  = entry.imageHref
        
        if (href != nil && !href!.isEmpty) {
            thumbnailImage.image = UIImage(data: AFTVClient.getImage(href!)!)
        }
        
        titleLabel.text = "\(entry.artist!)- \(entry.title!)"
        currentId = entry.uuid
    }
    
    // On websocket message, update the app
    func updateUI(response : String) {
        let event = NBJSON.Parser.parseJson(response)! as! Dictionary<String, Any>
        NBJSON.Utils.printJson(event)
        
        let eventObj = AFTVClient.parseEvent(event)
        let entry    = eventObj.entry
        let href     = entry?.imageHref
        
        if (href != nil) {
            thumbnailImage.image = UIImage(data: AFTVClient.getImage(href!)!)
        }
        
        titleLabel.text = "\(entry!.artist!)- \(entry!.title!)"
        currentId = entry?.uuid
    }
    
    func getQueue() -> String {
        return "/topic/" + PID;
    }
}


