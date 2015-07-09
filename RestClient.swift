//
//  RestClient.swift
//  REST-Test
//
//  Created by Michael Main on 1/8/15.
//  Copyright (c) 2015 Michael Main. All rights reserved.
//

import Foundation

func convertToJSON(value: AnyObject, prettyPrinted: Bool = false) -> NSData? {
    var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
    if NSJSONSerialization.isValidJSONObject(value) {
        if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
            return data
        }
    }
    return nil
}

func createQueryString(pairs: Dictionary<String, AnyObject>) -> String {
    var query = ""
    var sep = "?"
    
    for (key, value) in pairs {
        query += "\(sep)\(key)=\(value)"
        sep = "&"
    }
    
    return query
}

class RestClient {
    var request : NSMutableURLRequest = NSMutableURLRequest()
    var responseBody = Dictionary<String, JSON>()
    var error : NSError!
    
    var completed : Bool = false
    
    init(method: String, hostname : String, port : String, uri : String, headers : Dictionary<String, String>, body : Dictionary<String, AnyObject> = [:], ssl : Bool) {
        var url = "http://"
        
        if (ssl) {
            url = "https://"
        }
        
        url += hostname
        
        if (!port.isEmpty) {
            url += ":\(port)"
        }
        
        url += uri
        
        var json : NSData
        
        if (!body.isEmpty) {
            if (method != "GET" && method != "DELETE") {
                var json = convertToJSON(body)!
                request.HTTPBody = json
                addHeader("Content-Length", value: "\(json.length)")
                println("LENGTH: \(json.length) bytes")
            } else {
                url += createQueryString(body)
            }
        }
        
        addHeader("Accept", value: "application/json")
        addHeader("Content-Type", value: "application/json")
        
        println("URL: \(url)")
        
        request.URL = NSURL(string: url)
        request.HTTPMethod = method
        
        for (key, value) in headers {
            addHeader(key, value: value)
        }
    }
    
    func addHeader(key : String, value : String) -> RestClient {
        request.addValue(value, forHTTPHeaderField: key)
        return self
    }
    
    class func get(#hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], query : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "GET", hostname: hostname, port: port, uri: uri, headers: headers, body: query, ssl: ssl)
    }
    
    class func put(#hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], body : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "PUT", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
    
    class func post(#hostname : String, port : String, uri : String, headers : Dictionary<String, String> = [:], body : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "POST", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
    
    class func delete(#hostname : String, port : String, uri : String, headers : Dictionary<String, String> = [:], query : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "DELETE", hostname: hostname, port: port, uri: uri, headers: headers, body: query, ssl: ssl)
    }
    
    func sendSync() -> RestClient {
        var error : NSError?
        var data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: &error)
        
        if (error != nil || data == nil) {
            println("ERROR: \(error?.description)")
            completed = true
            return self
        }
        
        var jsonError : NSError?
        var json = JSON(data: data!, error: &jsonError)
        
        if (jsonError != nil) {
            println("ERROR: \(jsonError?.description)")
        }
        
        responseBody = json.dictionaryValue
        completed = true
        
        return self
    }
    
    func sendAsync() -> RestClient {
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler: { (response:NSURLResponse!, data: NSData!, error: NSError!) -> Void in
            if (error != nil || data == nil) {
                println("ERROR: \(error?.description)")
                self.responseBody = [:]
                self.completed = true
                return
            }
            
            var jsonError : NSError?
            var json = JSON(data: data!, error: &jsonError)
            
            if (jsonError != nil) {
                println("ERROR: \(jsonError?.description)")
                self.responseBody = [:]
            }
            
            self.responseBody = json.dictionaryValue
            self.completed = true
        })
        
        return self
    }
    
    func isComplete() -> Bool {
        return completed
    }
    
    func waitForCompletion() {
        while !completed {}
    }
    
    func getResponseBody() -> Dictionary<String,JSON> {
        return responseBody
    }
}