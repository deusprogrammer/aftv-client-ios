//
//  RestClient.swift
//  REST-Test
//
//  Created by Michael Main on 1/8/15.
//  Copyright (c) 2015 Michael Main. All rights reserved.
//

import Foundation

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
    var responseBody : Any?
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
        
        if (!body.isEmpty) {
            if (method != "GET" && method != "DELETE") {
                let json = NBJSON.Parser.stringify(body)
                request.HTTPBody = json.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
                addHeader("Content-Length", value: "\(json.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))")
                print("LENGTH: \(json.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)) bytes")
            } else {
                url += createQueryString(body)
            }
        }
        
        addHeader("Accept", value: "application/json")
        addHeader("Content-Type", value: "application/json")
        
        print("URL: \(url)")
        
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
    
    class func get(hostname hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], query : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "GET", hostname: hostname, port: port, uri: uri, headers: headers, body: query, ssl: ssl)
    }
    
    class func put(hostname hostname : String, port : String = "", uri : String, headers : Dictionary<String, String> = [:], body : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "PUT", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
    
    class func post(hostname hostname : String, port : String, uri : String, headers : Dictionary<String, String> = [:], body : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "POST", hostname: hostname, port: port, uri: uri, headers: headers, body: body, ssl: ssl)
    }
    
    class func delete(hostname hostname : String, port : String, uri : String, headers : Dictionary<String, String> = [:], query : Dictionary<String, AnyObject> = [:], ssl : Bool = false) -> RestClient {
        return RestClient(method: "DELETE", hostname: hostname, port: port, uri: uri, headers: headers, body: query, ssl: ssl)
    }
    
    func sendSync() throws -> RestClient {
        let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: nil)
        
        let jsonString : String = String(data: data, encoding: NSUTF8StringEncoding)!
        self.responseBody = NBJSON.Parser.parseJson(jsonString)
        self.completed = true
        
        return self
    }
    
    func sendAsync() -> RestClient {
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler: { (response:NSURLResponse?, data: NSData?, error: NSError?) -> Void in
            if (error != nil || data == nil) {
                print("ERROR: \(error?.description)")
                self.responseBody = [:]
                self.completed = true
                return
            }
            
            let jsonString : String = String(data: data!, encoding: NSUTF8StringEncoding)!
            self.responseBody = NBJSON.Parser.parseJson(jsonString)
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
    
    func getResponseBody() -> Any? {
        return responseBody
    }
}