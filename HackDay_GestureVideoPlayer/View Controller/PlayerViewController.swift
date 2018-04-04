//
//  PlayerViewController.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 4..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

enum Direction {
    case back
    case forward
}

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var playerView: UIView!
    @IBOutlet var outletCollection: [AnyObject]!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    
    var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private var playerItemContext = 0
    private var playerItemStatus: AVPlayerItemStatus = .unknown
    private var timeObserverToken: Any?
    
    private var chaseTime: CMTime = kCMTimeZero
    private var isSeekInProgress: Bool = false
    
    private var isFirstPlaying: Bool = true
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeToLandscapeLeft()
        
        navigationController?.isNavigationBarHidden = true
        navigationController?.navigationItem.backBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(ss))
    }
    
    @objc func ss() {
        print("back")
    }
    
    // 화면 크기가 다 결정되고 나서 해야 비디오가 꽉 차게 나옴.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        prepareToPlay()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        removePeriodicTimeObserver()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            if let statusNumber = change?[.newKey] as? NSNumber {
                playerItemStatus = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                playerItemStatus = .unknown
            }
            
            switch playerItemStatus {
            case .readyToPlay:
                guard isFirstPlaying else { return }
                
                play()
                isFirstPlaying = false
            case .failed:
                print("PlayerItem failed.")
            case .unknown:
                print("PlayerItem is not yet ready.")
            }
        }
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        switch sender.isSelected {
        case true:
            pause()
        case false:
            play()
        }
    }
    
    @IBAction func replayButtonTapped(_ sender: UIButton) {
        changeTenSeconds(to: .back)
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        changeTenSeconds(to: .forward)
    }
    
    @IBAction func lockButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        switch sender.isSelected {
        case true:
            setLockUI(isLocked: true)
        case false:
            setLockUI(isLocked: false)
        }
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        let valueRatio = sender.value / sender.maximumValue
        
        guard let totalSeconds = player?.currentItem?.duration.seconds else { return }
        let currentTimeSeconds = Double(valueRatio) * totalSeconds
        let timeToBeChanged = CMTime(seconds: currentTimeSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
//        player?.seek(to: timeToBeChanged, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        stopPlayingAndSeekSmoothlyToTime(newChaseTime: timeToBeChanged)
    }
    
    private func changeToLandscapeLeft() {
        let orientationValue = UIInterfaceOrientationMask.landscapeLeft.rawValue
        UIDevice.current.setValue(orientationValue, forKey: "orientation")
    }
    
    private func prepareToPlay() {
        guard let videoURL = videoURL else { return }
        let asset = AVURLAsset(url: videoURL, options: [AVURLAssetAllowsCellularAccessKey: false])
        
        let assetKeys = ["playable", "hasProtectedContent"]
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItem.addObserver(self,
                               forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.old, .new],
                               context: &playerItemContext)
        
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.videoGravity = .resizeAspectFill
        playerLayer?.frame = playerView.frame
        
        setPlayerUI(asset: asset)
        
        guard let playerLayer = playerLayer else { return }
        playerView.layer.addSublayer(playerLayer)
        
        addPeriodicTimeObserver()
    }
    
    private func setPlayerUI(asset: AVAsset) {
        totalTimeLabel.text = asset.duration.toTimeForamt
        if asset.duration.seconds / 3600 > 0 {
            currentTimeLabel.text = "00:00:00"
        } else {
            currentTimeLabel.text = "00:00"
        }
    }
    
    private func setLockUI(isLocked: Bool) {
        outletCollection.forEach { outlet in
            UIView.animate(withDuration: 0.5) {
                (outlet as? UIView)?.alpha = isLocked ? 0.0 : 1.0
            }
        }
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            self?.currentTimeLabel.text = time.seconds.toTimeFormat
            
            guard let timeSliderMaximumValue = self?.timeSlider.maximumValue,
                let assetDuration = self?.player?.currentItem?.duration.seconds else { return }
            let value = timeSliderMaximumValue * Float(time.seconds / assetDuration)
            self?.timeSlider.setValue(value, animated: true)
        })
    }
    
    private func removePeriodicTimeObserver() {
        guard let timeObserverToken = timeObserverToken else { return }
        player?.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
    
    private func play() {
        playButton.isSelected = true
        
        player?.play()
    }
    
    private func pause() {
        playButton.isSelected = false
        
        player?.pause()
    }
    
    private func changeTenSeconds(to direction: Direction) {
        guard let currentTimeSeconds = player?.currentTime().seconds else { return }
        let timeToBeChanged: CMTime = {
            switch direction {
            case .back:
                return CMTime(seconds: currentTimeSeconds - 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            case .forward:
                return CMTime(seconds: currentTimeSeconds + 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            }
        }()
        
        player?.seek(to: timeToBeChanged,
                     toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [weak self] _ in
            guard let isPlaying = self?.player?.isPlaying else { return }
            switch isPlaying {
            case true:
                self?.play()
            case false:
                self?.pause()
            }
        }
    }
    
    private func stopPlayingAndSeekSmoothlyToTime(newChaseTime:CMTime) {
        if CMTimeCompare(newChaseTime,chaseTime) != 0 {
            chaseTime = newChaseTime;
            
            if !isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
    
    private func trySeekToChaseTime() {
        guard playerItemStatus == .readyToPlay else { return }
        actuallySeekToTime()
    }
    
    private func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        player?.seek(to: seekTimeInProgress,
                     toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [weak self] isFinished in
                        guard let strongSelf = self else { return }
                        if CMTimeCompare(seekTimeInProgress, strongSelf.chaseTime) == 0 {
                            strongSelf.isSeekInProgress = false
                        } else {
                            strongSelf.trySeekToChaseTime()
                        }
                        
                        guard let isPlaying = self?.player?.isPlaying else { return }
                        switch isPlaying {
                        case true:
                            self?.play()
                        case false:
                            self?.pause()
                        }
        }
    }
}
