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
    lazy var title: String = { [weak self] in // retain cycle 피하자!
        guard let remoteURL = self?.remoteURL else { return "" }
        
        return remoteURL.lastPathComponent
    }()
    let remoteURL: URL
    var localURL: URL?
    var asset: AVURLAsset?
    var downloadTask: AVAssetDownloadTask?
    
    init(remoteURL: URL) {
        self.remoteURL = remoteURL
    }
    
    func setUpAssetDownload(downloadSession: AVAssetDownloadURLSession) {
        asset = AVURLAsset(url: remoteURL)
        guard let asset = asset else { return }
        
        downloadTask = downloadSession.makeAssetDownloadTask(asset: asset,
                                                             assetTitle: " ",
                                                             assetArtworkData: nil,
                                                             options: nil)
        
        downloadTask?.resume()
    }
}

extension VideoModel: AVAssetDownloadDelegate {
    
}
