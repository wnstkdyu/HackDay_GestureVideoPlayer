//
//  VideoModel.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 9..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import Foundation
import AVFoundation

class VideoModel: NSObject {
    // MARK: Public Properties
    public var title: String {
        return remoteURL.lastPathComponent
    }
    
    public let remoteURL: URL
    public var localURL: URL?
    public var asset: AVURLAsset?
    
    // MARK: Private Properties
    private var downloadTask: AVAssetDownloadTask?
    
    private let minimumBitrate: Int = 2000000
    
    init(remoteURL: URL) {
        self.remoteURL = remoteURL
    }
    
    public func setUpAssetDownload(downloadSession: AVAssetDownloadURLSession) {
        asset = AVURLAsset(url: remoteURL)
        guard let asset = asset else { return }
        
        // Retrieve the AVMediaSelectionGroup for the specified characteristic.
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            // Print its options.
            for option in group.options {
                print("Option: \(option.displayName)")
            }
        }
        
        let mediaSelectionGroup = asset.preferredMediaSelection
        print("asset의 미디어 셀렉션: \(mediaSelectionGroup)")
//        guard let mutableMediaSelection = mediaSelectionGroup.mutableCopy() as? AVMutableMediaSelection else { return }
        
        downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                             assetTitle: " ",
                                                             assetArtworkData: nil,
                                                             options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: minimumBitrate])
        
        downloadTask?.resume()
    }
}
