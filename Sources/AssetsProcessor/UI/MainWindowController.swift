//
//  MainWindowController.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/16.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async() {
            NSApplication.shared().terminate(nil)
        }
    }    
}
