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
    var mediaSelectionMap: [AVAssetDownloadTask: AVMediaSelection] = [:]
    private let downloadSessionIdentifier = "downloadSessionIdentifier"
    lazy private var downloadSession: AVAssetDownloadURLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: downloadSessionIdentifier)
        configuration.allowsCellularAccess = false
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                        assetDownloadDelegate: self,
                                                        delegateQueue: .main)
        
        return downloadSession
    }()
    
    private let cellIdentifier = "VideoListCell"
    
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
        setCollectionViewItemSize()
    }
    
    private func createVideoModelList() {
        videoModelList.append(VideoModel(remoteURL: videoURL))
        
        // UserDefaults에 저장해 놓은 localURL 확인 후 있다면 넣어 주기.
        for i in videoModelList.indices {
            let videoModel = videoModelList[i]
            
            if let localURLString = UserDefaults.standard.object(forKey: videoModel.remoteURL.absoluteString) as? String {
                let baseURL = URL(fileURLWithPath: NSHomeDirectory())
                let localURL = baseURL.appendingPathComponent(localURLString)
                
                videoModel.localURL = localURL
                videoModel.asset = AVURLAsset(url: localURL)
            }
        }
    }
    
    private func setCollectionViewItemSize() {
        guard let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        flowLayout.itemSize = CGSize(width: view.frame.width / 2 - flowLayout.minimumInteritemSpacing,
                                     height: view.frame.width / 2 - flowLayout.minimumLineSpacing)
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
        let videoListCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? VideoListCell ?? VideoListCell()
        videoListCell.videoLabel.text = videoModelList[indexPath.row].title
        
        return videoListCell
    }
}

extension VideoListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let playerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return }
        
        let videoModel = videoModelList[indexPath.row]
        if videoModel.localURL == nil || videoModel.asset?.assetCache?.isPlayableOffline == false {
            videoModel.setUpAssetDownload(downloadSession: downloadSession)
        }
        guard let asset = videoModel.asset else { return }
        playerViewController.playerManager = PlayerManager(asset: asset)
        
        navigationController?.pushViewController(playerViewController, animated: true)
    }
}

extension VideoListViewController: AVAssetDownloadDelegate {
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        guard let videoModel = (videoModelList.filter { $0.remoteURL == assetDownloadTask.urlAsset.url })
            .first else { return }
        videoModel.localURL = location
        
        UserDefaults.standard.set(location.relativePath, forKey: videoModel.remoteURL.absoluteString)
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
        print(resolvedMediaSelection)
        
        mediaSelectionMap.updateValue(resolvedMediaSelection, forKey: assetDownloadTask)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
    }
}
