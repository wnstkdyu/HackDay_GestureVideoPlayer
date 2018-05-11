//
//  VideoModel.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 9..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoModel: NSObject {
    // MARK: Public Properties
    public var title: String {
        return remoteURL.lastPathComponent
    }
    
    public let remoteURL: URL
    public var localURL: URL?
    public var asset: AVURLAsset
    public var thumbnailImage: UIImage?
    
    // MARK: Private Properties
    private var downloadTask: AVAssetDownloadTask?
    
    private let minimumBitrate: Int = 2000000
    
    init(remoteURL: URL) {
        self.remoteURL = remoteURL
        asset = AVURLAsset(url: remoteURL)
        super.init()
        
        getThumbnailImage()
    }
    
    public func setUpAssetDownload(downloadSession: AVAssetDownloadURLSession) {
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
    
    private func getThumbnailImage() {
        // 썸네일 이미지가 있는지 먼저 확인
        guard !asset.tracks(withMediaCharacteristic: .visual).isEmpty else { return }
        
        let imageGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        DispatchQueue.global().async { [weak self] in
            guard let strongSelf = self else { return }
            guard let thumbnailCGImage = try? imageGenerator.copyCGImage(at: CMTime(seconds: strongSelf.asset.duration.seconds / 2, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), actualTime: nil) else { return }
            
            strongSelf.thumbnailImage = UIImage(cgImage: thumbnailCGImage)
            
            NotificationCenter.default.post(name: NotificationName.didReceiveThumbnailImage, object: nil)
        }
        
    }
}
