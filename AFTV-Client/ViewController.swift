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
            dispatch_async(
                dispatch_get_main_queue()) {
                    self.refreshUI(self.PID)
            }
        }
    }
    
    func onConnect() {
        println("websocket is connected")
        client.connect("localhost", version: "1.2")
    }
    
    func onDisconnect(error: NSError?) {
        if let e = error {
            println("websocket is disconnected: \(e.localizedDescription)")
        }
    }
    
    func onReceive(message: String) {
        println("<<\(message)\n\n")
        var frame = STOMPFrame(stompString: message)
        
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
            println("An error has occured: \(frame.body)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sliderMoved(sender: UISlider) {
        var sliderValue : Int = Int(round(sender.value))
        ratingSlider.value = Float(sliderValue)
        
        ratingLabel.text = "\(sliderValue)/10"
    }
    
    @IBAction func submitVote(sender: UIButton) {
        var sliderValue : Int = Int(round(ratingSlider.value))
        vote(PID, vid: currentId!, comment: "", rating: sliderValue)
    }
    
    func vote(pid: String, vid : String, comment: String, rating : Int) {
        // RestClient async post
        var dict = RestClient.post(
            hostname: "localhost",
            port: "8080",
            uri: "/aftv-backend/v1/contest/\(pid)/entry/\(vid)/vote",
            body: [
                "comment" : comment,
                "value"  : rating
            ]
        ).sendSync().getResponseBody()
    }
    
    // Make a first REST call to get the initial state of the contest
    func refreshUI(pid : String) {
        ratingSlider.value = 0
        // RestClient sync get
        var entry = RestClient.get(
            hostname: "localhost",
            port: "8080",
            uri: "/aftv-backend/v1/contest/\(PID)/nowPlaying"
        ).sendSync().getResponseBody()
        
        titleLabel.text = "Not active";
        currentId = nil;
        
        var title = "Untitled"
        if(entry["title"] != nil) {
            title = entry["title"]!.stringValue
        }
        var artist = "Anonymous"
        if (entry["artist"] != nil) {
            artist = entry["artist"]!.stringValue
        }
        // Update thumbnail image
        var links = entry["links"]!.arrayValue
        var href = ""
        for link in links {
            var obj = link.dictionaryValue
            if obj["rel"]!.stringValue == "thumbnail" {
                href = obj["href"]!.stringValue
                break
            }
        }
        if (!href.isEmpty) {
            changeImageAsync(href)
        }
        
        titleLabel.text = "\(artist)- \(title)"
        currentId = entry["uuid"]?.stringValue
    }
    
    // On websocket message, update the app
    func updateUI(response : String) {
        var json = NBJSON.Parser.parseJson(response)! as! Dictionary<String, Any>
        NBJSON.Utils.printJson(json)
        
        // Update title and artist
        var entry = json["contestEntry"] as! Dictionary<String, Any>
        var title = "Untitled"
        if(entry["title"] != nil) {
            title = entry["title"] as! String
        }
        var artist = "Anonymous"
        if (entry["artist"] != nil) {
            artist = entry["artist"] as! String
        }
 
        // Update thumbnail image
        var links = entry["links"] as! Array<Any>
        var href = ""
        for link in links {
            var obj = link as! Dictionary<String, Any>
            if obj["rel"] as! String == "thumbnail" {
                href = obj["href"] as! String
                break
            }
        }
        if (!href.isEmpty) {
            changeImageAsync(href)
        }
        
        titleLabel.text = "\(artist)- \(title)"
        currentId = entry["uuid"] as? String

        //refreshUI(PID);
    }
    
    func changeImageAsync(urlString: String) {
        let url = NSURL(string: urlString)
        let request = NSURLRequest(URL: url!)
        let view = self
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            if (error != nil || data == nil) {
                println("ERROR: \(error?.description)")
            }
            view.thumbnailImage.image = UIImage(data: data)
        }
    }
    
    func getQueue() -> String {
        return "/topic/" + PID;
    }
}


