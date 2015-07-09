//
//  StarscreamAdapter.swift
//  WebSocketTest
//
//  Created by Michael Main on 1/16/15.
//  Copyright (c) 2015 Michael Main. All rights reserved.
//

import Foundation
import Starscream

class StarscreamAdapter : STOMPClientAdapter, STOMPOverWebSocket, WebSocketDelegate {
    var socket : WebSocket
    var delegate : STOMPClientDelegate?
    
    required init(scheme : String, host : String, path : String) {
        socket = WebSocket(
            url: NSURL(
                scheme: scheme,
                host: host,
                path: path)!)
        socket.connect()
        socket.delegate = self
    }
    
    func write(str: String) {
        socket.writeString(str)
    }
    
    func websocketDidConnect(socket: WebSocket) {
        if delegate != nil {
            delegate?.onConnect()
        }
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        if delegate != nil {
            delegate?.onDisconnect(error)
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        if delegate != nil {
            delegate?.onReceive(text)
        }
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: NSData) {
        
    }
}