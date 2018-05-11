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
    
    // MARK: Private Properties
    private lazy var videoModelList: [VideoModel] = []
    private var mediaSelectionMap: [AVAssetDownloadTask: AVMediaSelection] = [:]
    private let downloadSessionIdentifier = "downloadSessionIdentifier"
    private lazy var downloadSession: AVAssetDownloadURLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: downloadSessionIdentifier)
        configuration.allowsCellularAccess = false
        let downloadSession = AVAssetDownloadURLSession(configuration: configuration,
                                                        assetDownloadDelegate: self,
                                                        delegateQueue: .main)
        
        return downloadSession
    }()
    
    private let cellIdentifier = "VideoListCell"
    
    let videoMockURLs: [URL?] = [URL(string: "https://devimages-cdn.apple.com/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8"), URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"), URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"), URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8")]
    let videoURL = URL(string: "https://devimages-cdn.apple.com/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8")
    
    // MARK: Rotation Properties
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    // MARK: LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUp()
    }
    
    // MARK: Setup Methods
    private func setUp() {
        createVideoModelList()
        setCollectionViewItemSize()
        addNotificationObserver()
    }
    
    private func createVideoModelList() {
        videoMockURLs.forEach {
            guard let videoURL = $0 else { return }
            videoModelList.append(VideoModel(remoteURL: videoURL))
        }
        
        // UserDefaults에 저장해 놓은 localURL 확인 후 있다면 넣어 주기.
        for videoModel in videoModelList {
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
    
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveThumbnailImage), name: NotificationName.didReceiveThumbnailImage, object: nil)
    }
    
    // MARK: Notification Receiver
    @objc private func didReceiveThumbnailImage() {
        DispatchQueue.main.async { [weak self] in
            self?.collectionView.reloadData()
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
    // MARK: UICollectionViewDataSource Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return videoModelList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let videoListCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? VideoListCell ?? VideoListCell()
        
        let videoModel = videoModelList[indexPath.row]
        videoListCell.videoLabel.text = videoModel.title
        videoListCell.thumbnailImageView.image = videoModel.thumbnailImage
        
        return videoListCell
    }
}

extension VideoListViewController: UICollectionViewDelegate {
    // MARK: UICollectionViewDelegate Methods
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let playerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController else { return }
        
        let videoModel = videoModelList[indexPath.row]
        if videoModel.localURL == nil || videoModel.asset.assetCache?.isPlayableOffline == false {
            videoModel.setUpAssetDownload(downloadSession: downloadSession)
        }

        playerViewController.playerManager = PlayerManager(asset: videoModel.asset)
        
        navigationController?.pushViewController(playerViewController, animated: true)
    }
}

extension VideoListViewController: AVAssetDownloadDelegate {
    // MARK: AVAssetDownloadDelegate Methods
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
