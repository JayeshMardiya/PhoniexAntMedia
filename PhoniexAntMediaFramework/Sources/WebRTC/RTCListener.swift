//
//  RTCListener.swift
//  VoW
//
//  Created by Jayesh Mardiya on 27/01/20.
//  Copyright © 2020 Jayesh Mardiya. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import WebRTC
import RxSwift
import Reachability

public protocol RTCListenerDelegate {
    func showPasswordView(password: String, completion: @escaping (Bool) -> ())
    func showConnectionStatus(isConnected: Bool)
    func showErrorMessage(message: String)
    func webRTCClient(_ client: ClientBase, didSaveFile file: String, ofType type: String, toPath path: String)
}

public class RTCListener: NSObject {
    
    public var rtcListenerDelegate: RTCListenerDelegate?
    private var serverAddresses: [Data] = []
    var clientPresenter: ClientPresenter!
    
    public override init() {
        super.init()
    }
    
    public func connectToServer(server: NetService) {
        
        server.delegate = self
        server.resolve(withTimeout: 5.0)
    }
    
    public func disConnectFromServer() {
        if self.clientPresenter != nil {
            self.clientPresenter.disconnect()
        }
    }
    
    public func sendMessage(message: MessageData) {
        
        self.clientPresenter.sendTextMessage(message: message)
    }
    
    public func setVolume(volume: Double) {
        if clientPresenter != nil {
            self.clientPresenter.setVolume(volume: volume)
        }
    }
    
    public func muteEnable(isMute: Bool) {
        if clientPresenter != nil {
            if isMute {
                self.clientPresenter.muteAudio(isRemote: false)
            } else {
                self.clientPresenter.unmuteAudio(isRemote: false)
            }
        }
    }
}

extension RTCListener: ConnectDelegate {
    
    func didShowErrorMessage(message: String) {
        self.rtcListenerDelegate?.showErrorMessage(message: message)
    }
    
    func webRTCClient(_ client: ClientBase, didSaveFile file: String, ofType type: String, toPath path: String) {
        self.rtcListenerDelegate?.webRTCClient(client, didSaveFile: file, ofType: type, toPath: path)
    }
    
    func didSetPassword(password: String, completion: @escaping (Bool) -> ()) {
        
        self.rtcListenerDelegate?.showPasswordView(password: password, completion: { isCorrect in
            completion(isCorrect)
        })
    }
    
    func didIceConnectionStateChanged(iceConnectionState: RTCIceConnectionState) {}
    
    func didReceiveData(data: Data) {}
    
    func didReceiveMessage(message: MessageData) {}
    
    func didConnectWebRTC(client: ClientBase) {
        self.rtcListenerDelegate?.showConnectionStatus(isConnected: true)
    }
    
    func didDisconnectWebRTC(client: ClientBase) {
        self.rtcListenerDelegate?.showConnectionStatus(isConnected: false)
    }
}

extension RTCListener: NetServiceDelegate {
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        guard let addresses = sender.addresses
        else { return }
        
        self.serverAddresses = addresses
        guard let addr = addresses.first else { return }
        
        let socket = GCDAsyncSocket()
        do {
            self.clientPresenter = ClientPresenter(socket: socket, and: "listener")
            self.clientPresenter.delegate = self
            try socket.connect(toAddress: addr)
            socket.readData(to: GCDAsyncSocket.crlfData(), withTimeout: -1, tag: 0)
        } catch {
            return
        }
    }
}
