//
//  PlayerViewController.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 4..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVFoundation

class PlayerViewController: UIViewController {
    
    @IBOutlet var outletCollection: [AnyObject]!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    
    var videoURL: URL?
    private var timeObserverToken: Any?
    
    private var playerView: PlayerView {
        guard let playerView = view as? PlayerView else { return PlayerView() }
        
        return playerView
    }
    
    private var player: AVPlayer {
        get {
            guard let player = playerView.player else { return AVPlayer() }
            
            return player
        }
        set {
            playerView.player = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeToLandscapeLeft()
        
        createAssetAndPlay()
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        switch sender.isSelected {
        case true:
            pause()
        case false:
            play()
        }
        
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func replayButtonTapped(_ sender: UIButton) {
        replayBeforeTenSeconds()
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        forwardAfterTenSeconds()
    }
    
    @IBAction func lockButtonTapped(_ sender: UIButton) {
        switch sender.isSelected {
        case true:
            setLockUI(isLocked: true)
        case false:
            setLockUI(isLocked: false)
        }
        
        sender.isSelected = !sender.isSelected
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        let valueRatio = sender.value / sender.maximumValue
        
        guard let totalSeconds = player.currentItem?.duration.seconds else { return }
        let currentTimeSeconds = Double(valueRatio) * totalSeconds
        let timeToBeChanged = CMTime(seconds: currentTimeSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: timeToBeChanged, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    private func changeToLandscapeLeft() {
        let orientationValue = UIInterfaceOrientationMask.landscapeLeft.rawValue
        UIDevice.current.setValue(orientationValue, forKey: "orientation")
    }
    
    private func createAssetAndPlay() {
        guard let videoURL = videoURL else { return }
        let asset = AVURLAsset(url: videoURL, options: [AVURLAssetAllowsCellularAccessKey: false])
        let playableKey = "playable"
        
        asset.loadValuesAsynchronously(forKeys: [playableKey]) { [weak self] in
            var error: NSError?
            let status = asset.statusOfValue(forKey: playableKey, error: &error)
            switch status {
            case .loaded:
                let playerItem = AVPlayerItem(asset: asset)
                self?.player = AVPlayer(playerItem: playerItem)
                self?.addPeriodicTimeObserver()
                
                self?.play()
            case .failed:
                // Handle error.
                print("loading asset property failed")
            case .cancelled:
                // Terminate processing
                print("loading asset property cancelled")
            default:
                // Handle all other cases
                break
            }
        }
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
        outletCollection.forEach { ($0 as? UIView)?.isHidden = isLocked }
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            self?.currentTimeLabel.text = time.seconds.toTimeFormat
        })
    }
    
    private func play() {
        player.play()
    }
    
    private func pause() {
        player.pause()
    }
    
    private func replayBeforeTenSeconds() {
        let currentTimeSeconds = player.currentTime().seconds
        let timeBeforeTenSeconds = CMTime(seconds: currentTimeSeconds - 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: timeBeforeTenSeconds, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
    
    private func forwardAfterTenSeconds() {
        let currentTimeSeconds = player.currentTime().seconds
        let timeAfterTenSeconds = CMTime(seconds: currentTimeSeconds + 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        player.seek(to: timeAfterTenSeconds, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }
}
