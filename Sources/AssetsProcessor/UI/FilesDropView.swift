//
//  FilesDropView.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/16.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Cocoa

class FilesDropView: NSView {

    // 文件拖入后的回调事件
    typealias FilesDropHandler = ([String]) -> Swift.Void
    var filesDropHandler: FilesDropHandler?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer?.backgroundColor = CGColor(gray: 0, alpha: 0)
        // 注册'文件'类型拖动事件监听
        register(forDraggedTypes: [NSFilenamesPboardType])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let types = sender.draggingPasteboard().types, types.contains(NSFilenamesPboardType) {
            return .copy
        }
        return super.draggingEntered(sender)
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        super.prepareForDragOperation(sender)
        
        if let fileList = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? [String] {
            filesDropHandler?(fileList)
            return true
        }
        return false
    }
}
