//
//  AppSettings.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/18.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Cocoa

class AppSettings {

    class var `default`: AppSettings {
        return sharedAppSettings
    }
    
    fileprivate init() {}
    
    var generateNonRetina: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key_GenerateNonRetina)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key_GenerateNonRetina)
            UserDefaults.standard.synchronize()
        }
    }
    
    var upscaleFrom2x: Bool {
        get {
            return UserDefaults.standard.bool(forKey: Key_UpscaleFrom2x)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Key_UpscaleFrom2x)
            UserDefaults.standard.synchronize()
        }
    }
    
}

fileprivate let sharedAppSettings = AppSettings()
fileprivate let Key_GenerateNonRetina = "com.harley.x-processor.generate_non_retina"
fileprivate let Key_UpscaleFrom2x = "com.harley.x-processor.upscale_from_2x"
