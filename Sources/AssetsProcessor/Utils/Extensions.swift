//
//  Extensions.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/16.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Foundation
import Cocoa

extension String {
    var lastPathComponent: String {
        return (self as NSString).lastPathComponent
    }
    
    func appendingPathComponent(_ str: String) -> String {
        return (self as NSString).appendingPathComponent(str)
    }
    
    var pathExtension: String {
        return (self as NSString).pathExtension
    }
    
    var deletingPathExtension: String {
        return (self as NSString).deletingPathExtension
    }
    
    func appendingPathExtension(_ ext: String) -> String {
        return (self as NSString).appendingPathExtension(ext) ?? self
    }
}

extension Int {
    var double: Double {
        return Double(self)
    }
}

// MARK: - Image Resizing
extension NSImage {
    
    func resizedTo(scale: CGFloat) -> NSImage? {
        guard let rep = representations.first as? NSBitmapImageRep else {
            return nil
        }
        
        var pixelSize = NSSize(width: rep.pixelsWide, height: rep.pixelsHigh)
        // issue #8: https://github.com/rickytan/RTImageAssets/issues/8
        if pixelSize.width == 0 || pixelSize.height == 0 {
            pixelSize = rep.size;
        }
        
        let scaleSize = NSSize(width: floor(pixelSize.width * scale), height: floor(pixelSize.height * scale))
        return resizedTo(size: scaleSize)
    }
    
    func resizedTo(size: CGSize) -> NSImage? {
        guard let rep = representations.first as? NSBitmapImageRep,
         let imageRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: rep.bitsPerSample, samplesPerPixel: rep.samplesPerPixel, hasAlpha: rep.hasAlpha, isPlanar: rep.isPlanar, colorSpaceName: rep.colorSpaceName, bytesPerRow: 0, bitsPerPixel: 0) else {
            // issue #21: https://github.com/rickytan/RTImageAssets/issues/21
            return nil
        }
        imageRep.size = size
        
        let context = NSGraphicsContext(bitmapImageRep: imageRep)
//        if context == nil, let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSCalibratedRGBColorSpace, bytesPerRow: 0, bitsPerPixel: 0) {
//            // issue #24: https://github.com/rickytan/RTImageAssets/issues/24
//            rep.size = size
//            imageRep = rep
//            context = NSGraphicsContext(bitmapImageRep: imageRep)
//        } else {
//            return nil
//        }
        
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.setCurrent(context)
        draw(in: NSRect(x: 0, y: 0, width: size.width, height: size.height))
        NSGraphicsContext.restoreGraphicsState()
        
        guard let data = imageRep.representation(using: .PNG, properties: [:]), let image = NSImage(data: data) else {
            return nil
        }
        return image
    }
    
    func save(to filePath: String, type: NSBitmapImageFileType) -> Bool {
        
        guard let tiffRep = tiffRepresentation else {
            return false
        }
        
        var data: Data? = nil
        if type == .TIFF {
            data = tiffRep
        } else if let rep = NSBitmapImageRep(data: tiffRep), let repData = rep.representation(using: type, properties: [:]) {
            data = repData
        }
        
        let url = URL(fileURLWithPath: filePath)
        guard data != nil else {
            return false
        }
        do {
            try data!.write(to: url)
        } catch {
            return false
        }
        return true
    }
}

extension NSImage {
    
    func tinted(color:NSColor) -> NSImage {
        let size        = self.size
        let imageBounds = NSMakeRect(0, 0, size.width, size.height)
        let copiedImage = self.copy() as! NSImage
        
        copiedImage.lockFocus()
        color.set()
        NSRectFillUsingOperation(imageBounds, .sourceAtop)
        copiedImage.unlockFocus()
        
        return copiedImage
    }
}


