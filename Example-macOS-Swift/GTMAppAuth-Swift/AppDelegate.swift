//
//  AppDelegate.swift
//  GTMAppAuth-Swift
//
//  Created by Grant K2 on 20/02/2018.
//  Copyright © 2018 Google. All rights reserved.
//

import Cocoa
import GTMAppAuth

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow?
    
    var currentAuthorizationFlow:OIDAuthorizationFlowSession?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Register for Call back URL events
        let aem = NSAppleEventManager.shared();
        aem.setEventHandler(self, andSelector: #selector(AppDelegate.handleGetURLEvent(event:replyEvent:)), forEventClass: AEEventClass(kInternetEventClass), andEventID: AEEventID(kAEGetURL))

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationWillFinishLaunching(notification: NSNotification?) {
        // -- launch the app with url
    }
    
    @objc func handleGetURLEvent(event: NSAppleEventDescriptor, replyEvent: NSAppleEventDescriptor) {
        
    let urlString = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue!
        let url = URL(string: urlString!)!
        currentAuthorizationFlow?.resumeAuthorizationFlow(with: url)
    }
}

