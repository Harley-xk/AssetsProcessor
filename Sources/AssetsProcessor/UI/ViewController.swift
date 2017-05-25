//
//  ViewController.swift
//  X-Processor
//
//  Created by Harley.xk on 2017/5/16.
//  Copyright © 2017年 Harley.xk. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var filesDropView: FilesDropView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var statusLabel: NSTextField!
//    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak var titleView: NSView! {
        didSet {
            titleView.wantsLayer = true
            titleView.layer?.backgroundColor = NSColor(white: 1, alpha: 1).cgColor
        }
    }

    @IBOutlet weak var genNonretinaCheck: NSButton! {
        didSet {
            genNonretinaCheck.state = AppSettings.default.generateNonRetina ? 1 : 0
            genNonretinaCheck.attributedTitle = NSAttributedString(string: "Generate 1x",
                                                                   attributes: [NSForegroundColorAttributeName : NSColor.white])
        }
    }
    @IBOutlet weak var upscaleCheck: NSButton! {
        didSet {
            upscaleCheck.state = AppSettings.default.upscaleFrom2x ? 1 : 0
            upscaleCheck.attributedTitle = NSAttributedString(string: "Upscale from 2x",
                                                              attributes: [NSForegroundColorAttributeName : NSColor.white])
        }
    }

    
    var imageSets: [ImageSet] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        filesDropView.filesDropHandler = filesDropHandler(files:)
        statusLabel.stringValue = "Drag and drop folders in to start"
//        progressBar.isHidden = true
        
//        NotificationCenter.default.addObserver(forName: .progressChanged, object: nil, queue: nil) { (_) in
//            self.updateForProgress(AssetsProcessor.shared.finishedCount, total: AssetsProcessor.shared.totalCount)
//        }
        
//        NotificationCenter.default.addObserver(forName: .progressFinished, object: nil, queue: nil) { (_) in
//            statusLabel.stringValue = "All done! Have fun!"
//            self.tableView.reloadData()
//        }
        
        view.layer?.backgroundColor = NSColor.blue.cgColor
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func upscaleAction(_ sender: Any) {
        AppSettings.default.upscaleFrom2x = upscaleCheck.state == 1
    }
    
    @IBAction func genNoretinaAction(_ sender: Any) {
        AppSettings.default.generateNonRetina = genNonretinaCheck.state == 1
    }
    
    private func filesDropHandler(files: [String]) {
        
        let assets = AssetsProcessor.shared.findAssets(at: files)
        imageSets = assets
        
        tableView.reloadData()
        
        AssetsProcessor.shared.processAssets(in: imageSets) {
            self.statusLabel.stringValue = "All done! Have fun!"
            self.tableView.reloadData()
        }
        
        statusLabel.stringValue = "Processing..."
//        updateForProgress(0, total: AssetsProcessor.shared.totalCount)
    }
    
//    private func updateForProgress(_ finished: Int, total: Int) {
//        self.progressBar.doubleValue = finished.double
//        self.progressBar.maxValue = total.double
//        
//        if finished >= total {
//            statusLabel.stringValue = "All done! Have fun!"
//            progressBar.isHidden = true
//        } else {
//            statusLabel.stringValue = "Processing...(\(finished)/\(total))"
//            progressBar.isHidden = false
//        }
//    }

    // MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return imageSets.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.make(withIdentifier: "ImageSetCell", owner: self) as! ImageSetCell
        
        cell.loadData(imageSet: imageSets[row])
        cell.layer?.backgroundColor = row % 2 == 0 ? NSColor.clear.cgColor : NSColor(white: 1, alpha: 0.05).cgColor
        
        return cell
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}

class ImageSetCell: NSTableCellView {
    
    @IBOutlet weak var leadingCons: NSLayoutConstraint!
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var countLabel: NSTextField!
    @IBOutlet weak var iconView: NSImageView!
    
    @IBOutlet weak var statusCheckView: NSView!
    @IBOutlet weak var check_1x: NSImageView!
    @IBOutlet weak var check_2x: NSImageView!
    @IBOutlet weak var check_3x: NSImageView!
    
    @IBOutlet weak var nameCheckView: NSImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
    
    func loadData(imageSet: ImageSet) {
        leadingCons.constant = CGFloat(20 + imageSet.level * 20)
        nameLabel.stringValue = imageSet.name
        countLabel.stringValue = "\(imageSet.children.count) Sets "
        
        if imageSet.type == .set {
            countLabel.isHidden = true
            statusCheckView.isHidden = false
            iconView.image = imageSet.image
            
            check_1x.image = imageSet.status_1x.icon
            check_2x.image = imageSet.status_2x.icon
            check_3x.image = imageSet.status_3x.icon
            nameCheckView.image = #imageLiteral(resourceName: "icn-check").tinted(color: imageSet.nameGenerated ? .green : .yellow)
        } else {
            countLabel.isHidden = imageSet.type == .asset ? true : false
            statusCheckView.isHidden = true
            iconView.image = #imageLiteral(resourceName: "icn-group")
        }
    }
}

