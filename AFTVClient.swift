//
//  AFTVClient.swift
//  AFTV-Client
//
//  Created by Michael Main on 10/6/15.
//  Copyright © 2015 Michael Main. All rights reserved.
//

import Foundation

class ContestEntry {
    var id : Int?
    var uuid : String?
    var title : String?
    var description : String?
    var artist : String?
    var imageHref : String?
}

class Contest {
    var id : Int?
    var uuid : String?
    var title : String?
    var description : String?
    var lastEvent : Int?
    var isActive : Bool?
}

class Event {
    var contest : Contest?
    var entry : ContestEntry?
    var trigger : String?
}

class AFTVClient {
    class func getActiveContests() -> Array<Contest> {
        let contests = Array<Contest>()
        
        return contests
    }
    
    class func vote(pid : String, vid : String, comment : String, rating : Int) {
        // RestClient async post
        NBRestClient.post(
            hostname: "localhost",
            port: "8080",
            uri: "/aftv-backend/v1/contest/\(pid)/entry/\(vid)/vote",
            body: [
                "comment" : comment,
                "value"  : rating
            ]
            ).sendSync()
    }
    
    class func getCurrentlyPlaying(pid : String) -> ContestEntry {
        let entry = NBRestClient.get(
            hostname: "localhost",
            port: "8080",
            uri: "/aftv-backend/v1/contest/\(pid)/nowPlaying"
            ).sendSync().getResponseBody() as! Dictionary<String, Any>
        
        return getEntry(entry)
    }
    
    class func parseEvent(event : Dictionary<String, Any>) -> Event {
        let eventObj : Event = Event()
        
        let contest = event["contest"] as? Dictionary<String, Any>
        let entry   = event["contestEntry"] as? Dictionary<String, Any>
        let trigger = event["trigger"] as? String
        
        eventObj.contest = getContest(contest!)
        eventObj.entry   = getEntry(entry!)
        eventObj.trigger = trigger
        
        return eventObj
    }
    
    class func getContest(contest : Dictionary<String, Any>) -> Contest {
        let contestObj : Contest = Contest()
        
        // Create contest
        contestObj.id = contest["id"] as? Int
        contestObj.title = contest["title"] as? String
        contestObj.description = contest["description"] as? String
        contestObj.uuid = contest["uuid"] as? String
        contestObj.isActive = contest["isActive"] as? Bool
        contestObj.lastEvent = contest["lastEvent"] as? Int
        
        return contestObj
    }
    
    class func getEntry(entry : Dictionary<String, Any>) -> ContestEntry {
        let entryObj : ContestEntry = ContestEntry()
        
        // Create entry
        entryObj.id = entry["id"] as? Int
        entryObj.uuid = entry["uuid"] as? String
        entryObj.title = entry["title"] as? String
        entryObj.description = entry["description"] as? String
        entryObj.artist = entry["artist"] as? String
        entryObj.imageHref = getLink(entry, linkName: "thumbnail")
        
        return entryObj
    }
    
    class func getLink(resource : Dictionary<String, Any>, linkName : String) -> String? {
        let links = resource["links"] as! Array<Any>
        for link in links {
            var obj = link as! Dictionary<String, Any>
            if obj["rel"] as! String == linkName {
                return obj["href"] as? String
            }
        }
        
        return nil
    }
    
    class func getImage(urlString : String) -> NSData? {
        do {
            let url = NSURL(string: urlString)
            let request = NSURLRequest(URL: url!)
            var response : NSURLResponse? = NSURLResponse()
            return try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        } catch let error as NSError {
            print(error)
            return nil
        }
    }
}