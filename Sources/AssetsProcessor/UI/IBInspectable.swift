//
//  IBInspectable.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/16.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Foundation
import AppKit

extension NSView {
    @IBInspectable var cornerRadius: CGFloat? {
        set {
            layer?.cornerRadius = cornerRadius ?? 0
        }
        get {
            return layer?.cornerRadius
        }
    }
}
