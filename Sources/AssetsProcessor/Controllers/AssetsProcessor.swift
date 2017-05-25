//
//  AssetsProcessor.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/16.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Cocoa

class AssetsProcessor: NSObject {

    static let sharedProcessor = AssetsProcessor()
    class var shared: AssetsProcessor {
        return sharedProcessor
    }
    
    func findAssets(at paths: [String]) -> [ImageSet] {
        var imageSets: [ImageSet] = []
        for path in paths {
            let sets = findImageSets(at: path)
            imageSets.append(contentsOf: sets)
        }
        return imageSets
    }
    
    private func findImageSets(at path: String) -> [ImageSet] {
        var imageSets: [ImageSet] = []
        let ext = path.pathExtension
        if ext == ImageSetType.asset.rawValue, let asset = ImageSet(path: path) {
            asset.level = 0
            imageSets.append(asset)
            imageSets.append(contentsOf: findChildren(for: asset))
        } else {
            if let files = try? FileManager.default.contentsOfDirectory(atPath: path) {
                for name in files {
                    let filePath = path.appendingPathComponent(name)
                    imageSets.append(contentsOf: findImageSets(at: filePath))
                }
            }
        }
        return imageSets
    }
    
    private func findChildren(for imageSet: ImageSet) -> [ImageSet]  {
        guard imageSet.type == .asset || imageSet.type == .group else {
            return []
        }
        
        var imageSets: [ImageSet] = []
        if let files = try? FileManager.default.contentsOfDirectory(atPath: imageSet.path) {
            for name in files {
                let path = imageSet.path.appendingPathComponent(name)
                if let set = ImageSet(path: path) {
                    if set.type == .icon {
                        continue
                    }
                    set.level = imageSet.level + 1
                    imageSets.append(set)
                    if set.type == .set {
                        imageSet.children.append(set)
                    } else if set.type != .icon {
                        imageSets.append(contentsOf: findChildren(for: set))
                    }
                }
            }
            return imageSets
        }
        return []
    }
    
    var finishedCount = 0
    var totalCount = 0
    
    func processAssets(in groups: [ImageSet], finished: (() -> Swift.Void)? = nil) {
        totalCount = groups.count
        finishedCount = 0
        DispatchQueue.global().async {
            var setsToProcess: [ImageSet] = []
            for group in groups {
                setsToProcess.append(contentsOf: group.children)
            }
            self.totalCount = setsToProcess.count
            for set in setsToProcess {
                set.generateMissing()
                self.finishedCount += 1
//                DispatchQueue.main.async {
//                    NotificationCenter.default.post(name: .progressChanged, object: nil)
//                }
            }
            DispatchQueue.main.async {
                finished?()
//                NotificationCenter.default.post(name: .progressFinished, object: nil)
            }
        }
    }
}

//extension Notification.Name {
//    static var progressChanged = Notification.Name("ProgressChanged")
//    static var progressFinished = Notification.Name("ProgressFinished")
//}



