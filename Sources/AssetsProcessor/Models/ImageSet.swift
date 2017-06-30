//
//  ImageSet.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/16.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Cocoa

enum ImageSetType: String {
    case asset = "xcassets"
    case icon = "appiconset"
    case group = "group"
    case set = "imageset"
}

enum ImageGenerationStatus {
    case none
    case exists
    case generated
    case failed
    
    var icon: NSImage {
        switch self {
        case .none:
            return #imageLiteral(resourceName: "icn-none").tinted(color: .lightGray)
        case .exists:
            return #imageLiteral(resourceName: "icn-check").tinted(color: .yellow)
        case .generated:
            return #imageLiteral(resourceName: "icn-check").tinted(color: .green)
        case .failed:
            return #imageLiteral(resourceName: "icn-cross").tinted(color: .red)
        }
    }
}

class ImageSet: Model {
    
    var name: String
    var path: String
    var type: ImageSetType
    var level = 0
    
    var children: [ImageSet] = []
    
    var error: Error?
    
    init?(path: String) {
        let ext = path.pathExtension
        if let type = ImageSetType(rawValue: ext) {
            self.type = type
        } else {
            let p = Path(path)
            if !p.fileExist.isFile {
                self.type = .group
            } else {
                return nil
            }
        }
        
        self.path = path
        name = path.lastPathComponent.deletingPathExtension
        super.init()
        
        let jsonFile = Path(path).resource("Contents.json")
        if let data = try? Data(contentsOf: jsonFile.url), let dict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String : Any] {
            property = dict ?? [:]
            images = property["images"] as? [[String : Any]] ?? []
        }
    }
    
    var image: NSImage? {
        
        guard let index = _3xImageIndex ?? _2xImageIndex ?? _1xImageIndex else {
            return nil
        }
        let dict = images[index]
        guard let imageName = dict[KeyImageFilename] as? String else {
            return nil
        }

        let imagePath = path.appendingPathComponent(imageName)
        return NSImage(contentsOfFile: imagePath)
    }
    
    
    fileprivate var property: [String : Any] = [:]
    fileprivate var isChanged = false
    fileprivate var images: [[String : Any]] = []
    
    fileprivate(set) var status_1x: ImageGenerationStatus = .none
    fileprivate(set) var status_2x: ImageGenerationStatus = .none
    fileprivate(set) var status_3x: ImageGenerationStatus = .none
    fileprivate(set) var nameGenerated = false
}

let KeyImageIdiom = "idiom"
let KeyImageScale = "scale"
let KeyImageSize = "size"
let KeyImageFilename = "filename"
let KeyImageSubtype = "subtype"
let KeyImageResizing = "resizing"

extension ImageSet {
    
    func setFileName(_ name: String, for scale: String, resizing: [String : Any]? = nil) {
        for i in 0 ..< images.count {
            let dict = images[i]
            if let str = dict[KeyImageScale] as? String, str == scale,
                let idom = dict[KeyImageIdiom] as? String, ["iphone", "universal"].contains(idom) {
                images[i][KeyImageFilename] = name
                if resizing != nil {
                    images[i][KeyImageResizing] = resizing
                }
                isChanged = true
            }
        }
    }
    
    func resizing(from resizing: [String : Any]?, with scale: CGFloat, imageSize: NSSize) -> [String : Any]? {
        
        guard var value = resizing else {
            return nil
        }
        var width = imageSize.width
        var height = imageSize.height
        
        if var capInsets = value["cap-insets"] as? [String : Any] {
            if let v = capInsets["bottom"] as? Int {
                let bottom = ceil(CGFloat(v) * scale)
                height -= bottom
                capInsets["bottom"] = bottom
                value["cap-insets"] = capInsets
            }
            if let v = capInsets["top"] as? Int {
                let top = ceil(CGFloat(v) * scale)
                height -= top
                capInsets["top"] = top
                value["cap-insets"] = capInsets
            }
            if let v = capInsets["right"] as? Int {
                let right = ceil(CGFloat(v) * scale)
                width -= right
                capInsets["right"] = right
                value["cap-insets"] = capInsets
            }
            if let v = capInsets["left"] as? Int {
                let left = ceil(CGFloat(v) * scale)
                width -= left
                capInsets["left"] = left
                value["cap-insets"] = capInsets
            }
        }
        if var center = value["center"] as? [String : Any] {
            if let w = center["width"] as? Int {
                center["width"] = max(1, min(width, ceil(CGFloat(w) * scale)))
                value["center"] = center
            }
            if let h = center["height"] as? Int {
                center["height"] = max(1, min(width, ceil(CGFloat(h) * scale)))
                value["center"] = center
            }
        }
        return value
    }
    
    func filename(for imageName: String, scaleExtension: String) -> String {
        var name = imageName.deletingPathExtension
        if let range = imageName.range(of: "@2x") {
            name = imageName.substring(to: range.lowerBound)
        }
        if let range = imageName.range(of: "@3x") {
            name = imageName.substring(to: range.lowerBound)
        }
        
        var final = String(format: "%@%@.png", name, scaleExtension)
        var count = 0
        while FileManager.default.fileExists(atPath: path.appendingPathComponent(final)) {
            final = String(format: "%@%@~%ld.png", name, scaleExtension, count)
            count += 1
        }
        return final
    }
    
    var _3xImageIndex: Int? {
        for i in 0 ..< images.count {
            let dict = images[i]
            if let scale = dict[KeyImageScale] as? String,
                scale == "3x",
                let fileName = dict[KeyImageFilename] as? String
            {
                let filePath = path.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: filePath) {
                    return i
                }
            }
        }
        return nil
    }

    var _2xImageIndex: Int? {
        for i in 0 ..< images.count {
            let dict = images[i]
            if let scale = dict[KeyImageScale] as? String, scale == "2x",
                let fileName = dict[KeyImageFilename] as? String,
                let idom = dict[KeyImageIdiom] as? String,
                ["iphone", "universal"].contains(idom)
            {
                let filePath = path.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: filePath) {
                    return i
                }
            }
        }
        return nil
    }
    
    var _1xImageIndex: Int? {
        for i in 0 ..< images.count {
            let dict = images[i]
            if let scale = dict[KeyImageScale] as? String,
                scale == "1x",
                let fileName = dict[KeyImageFilename] as? String
            {
                let filePath = path.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: filePath) {
                    return i
                }
            }
        }
        return nil
    }
    
    func generateMissing() {
        
        generate1xIfNeeds()
        generate2xIfNeeds()
        generate3xIfNeeds()
        
        postProcess()
    }
    
    func postProcess() {
        self.rename()
        
        property["images"] = images
        if isChanged, let data = try? JSONSerialization.data(withJSONObject: property, options: .prettyPrinted) {
            let contentPath = path.appendingPathComponent("Contents.json")
            try? data.write(to: URL(fileURLWithPath: contentPath))
        }
    }
    
    func generate1xIfNeeds() {
        guard AppSettings.default.generateNonRetina else {
            return
        }
        if let _ = _1xImageIndex {
            status_1x = .exists
            return
        }
        
        var idx: Int
        var scale: CGFloat = 1 / 3
        if let index = _3xImageIndex {
            idx = index
        } else if let index = _2xImageIndex {
            scale = 1 / 2
            idx = index
        } else {
            status_1x = .failed
            return
        }
        
        let dict = images[idx]
        guard let imageName = dict[KeyImageFilename] as? String else {
            status_1x = .failed
            return
        }
        
        let url = path.appendingPathComponent(imageName)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: url)),
            let image = NSImage(data: data),
            let scaled = image.resizedTo(scale: scale)
        else {
            status_1x = .failed
            return
        }
        
        let fileName = filename(for: imageName, scaleExtension: "")
        if scaled.save(to: path.appendingPathComponent(fileName), type: NSPNGFileType)
        {
            let resizing = dict[KeyImageResizing] as? [String : Any]
            setFileName(fileName, for: "1x", resizing: self.resizing(from: resizing, with: scale, imageSize: scaled.size))
            status_1x = .generated
        } else {
            status_1x = .failed
        }
    }
    
    func generate2xIfNeeds() {
        if let _ = _2xImageIndex {
            status_2x = .exists
            return
        }
        
        guard let idx = _3xImageIndex else {
            status_2x = .none
            return
        }

        let dict = images[idx]
        guard let imageName = dict[KeyImageFilename] as? String else {
            status_2x = .failed
            return
        }
        
        let scale: CGFloat = 2 / 3
        let url = path.appendingPathComponent(imageName)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: url)),
            let image = NSImage(data: data),
            let scaled = image.resizedTo(scale: scale)
            else {
                status_2x = .failed
                return
        }
        let fileName = filename(for: imageName, scaleExtension: "@2x")
        if scaled.save(to: path.appendingPathComponent(fileName), type: NSPNGFileType)
        {
            let resizing = dict[KeyImageResizing] as? [String : Any]
            setFileName(fileName, for: "2x", resizing: self.resizing(from: resizing, with: scale, imageSize: scaled.size))
            status_2x = .generated
        } else {
            status_2x = .failed
        }
    }
    
    func generate3xIfNeeds() {
        
        if let _ = _3xImageIndex {
            status_3x = .exists
            return
        }
        
        guard AppSettings.default.upscaleFrom2x else {
            return
        }
        
        guard let idx = _2xImageIndex else {
            status_3x = .none
            return
        }
        
        let dict = images[idx]
        guard let imageName = dict[KeyImageFilename] as? String else {
            status_3x = .failed
            return
        }
        
        let scale: CGFloat = 1.5
        let url = path.appendingPathComponent(imageName)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: url)),
            let image = NSImage(data: data),
            let scaled = image.resizedTo(scale: scale)
            else {
                status_3x = .failed
                return
        }
        let fileName = filename(for: imageName, scaleExtension: "@3x")
        if scaled.save(to: path.appendingPathComponent(fileName), type: NSPNGFileType)
        {
            let resizing = dict[KeyImageResizing] as? [String : Any]
            setFileName(fileName, for: "3x", resizing: self.resizing(from: resizing, with: scale, imageSize: scaled.size))
            status_3x = .generated
        } else {
            status_3x = .failed
        }
    }
    
    func rename() {
        
        print(images)
        
        let renameFilename = path.lastPathComponent.deletingPathExtension

        for i in 0 ..< images.count {
            let dict = images[i]
            if let fileName = dict[KeyImageFilename] as? String, fileName.characters.count > 0 {
                
                if let scale = dict[KeyImageScale] as? String, scale != "1x" {
                    let name = String(format: "%@@%@", renameFilename, scale).appendingPathExtension(fileName.pathExtension)
                    if name == fileName {
                        continue
                    }
                }
                
                let filePath = path.appendingPathComponent(fileName)
                let backfile = path.appendingPathComponent(fileName.deletingPathExtension).appending("__backup~").appendingPathExtension(fileName.pathExtension)
                
                do {
                    try FileManager.default.moveItem(atPath: filePath, toPath: backfile)
                } catch {
                    continue
                }
                
                nameGenerated = true
                images[i][KeyImageFilename] = backfile.lastPathComponent
                isChanged = true
            }
        }
        
        for i in 0 ..< images.count {
            let dict = images[i]
            if var fileName = dict[KeyImageFilename] as? String, fileName.characters.count > 0 {
                var ext = fileName.pathExtension
                if ext.characters.count <= 0 {
                    ext = "png"
                }
                
                let filePath = path.appendingPathComponent(fileName)
                fileName = renameFilename
                if let idiom = dict[KeyImageIdiom] as? String, idiom == "ipad" {
                    fileName = renameFilename.appending("~ipad")
                }
                if let type = dict[KeyImageSubtype] as? String, type == "retina4" {
                    fileName = renameFilename.appending("-568h")
                }
                if let scale = dict[KeyImageScale] as? String, scale != "1x" {
                    fileName = String(format: "%@@%@", fileName, scale)
                }
                fileName = fileName.appendingPathExtension(ext)
                let newPath = path.appendingPathComponent(fileName)
                
                /// 替换前尝试移除原始文件（如果存在的话）
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: filePath), filePath != newPath {
                    try? fileManager.removeItem(atPath: newPath)
                    do {
                        try FileManager.default.moveItem(atPath: filePath, toPath: newPath)
                    } catch {
                        self.error = error
                        continue
                    }
                }
                images[i][KeyImageFilename] = fileName
//                isChanged = true
            }
        }
    }
}


