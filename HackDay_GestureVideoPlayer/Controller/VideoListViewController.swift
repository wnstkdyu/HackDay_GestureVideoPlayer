//
//  VideoListViewController.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 4..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVFoundation

class VideoListViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    lazy private var videoModelList: [VideoModel] = []
    private let downloadSessionIdentifier = "downloadSessionIdentifier"
    lazy private var downloadSession: AVAssetDownloadURLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: downloadSessionIdentifier)
        configuration.allowsCellularAccess = false
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                        assetDownloadDelegate: self,
                                                        delegateQueue: .main)
        
        return downloadSession
    }()
    
    private let cellIdentifier = "videoCollectionViewCell"
    
    let videoURL: URL = URL(string: "https://devimages-cdn.apple.com/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8")!
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createVideoModelList()
    }
    
    private func createVideoModelList() {
        videoModelList.append(VideoModel(remoteURL: videoURL))
        
        // UserDefaults에 저장해 놓은 localURL 확인 후 있다면 넣어 주기.
        for i in videoModelList.indices {
            let videoModel = videoModelList[i]
            
            if let localURLString = UserDefaults.standard.object(forKey: videoModel.remoteURL.absoluteString) as? String {
                guard let localURL = URL(string: localURLString) else { continue }
                videoModel.localURL = localURL
            }
        }
    }
    
//    private func restorePendingDownloads() {
//        downloadSession.getAllTasks { tasks in
//            for task in tasks {
//                guard let avAssetDownloadTask = task as? AVAssetDownloadTask else { continue }
//
//                videoModelList
//            }
//        }
//    }
}

extension VideoListViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoModelList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
        
        return cell
    }
}

extension VideoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
}

extension VideoListViewController: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard let remoteURL = (videoModelList.filter {
            guard let localURL = $0.localURL else { return false }
            
            return localURL == location
        }).first?.remoteURL else { return }
        
        UserDefaults.standard.set(location.relativePath, forKey: remoteURL.absoluteString)
    }
}