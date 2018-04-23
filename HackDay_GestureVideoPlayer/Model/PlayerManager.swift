//
//  PlayerManager.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 23..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import Foundation
import AVFoundation

protocol PlayerManagerDelegate: class {
    func isPlayedFirst()
    func setTimeObserverValue(time: CMTime)
    func playerPlayed()
    func playerPaused()
}

class PlayerManager: NSObject {
    weak var delegate: PlayerManagerDelegate?
    
    var asset: AVAsset
    var player: AVPlayer
    private var playerLayer: AVPlayerLayer
    
    private var playerItemContext = 0
    private var playerItemStatus: AVPlayerItemStatus = .unknown
    var isFirstPlaying: Bool = true
    
    private var timeObserverToken: Any?
    
    private var chaseTime: CMTime = kCMTimeZero
    private var isSeekInProgress: Bool = false
    
    init(asset: AVAsset) {
        self.asset = asset
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
    }
    
    deinit {
        removePeriodicTimeObserver()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            if let statusNumber = change?[.newKey] as? NSNumber {
                guard let status = AVPlayerItemStatus(rawValue: statusNumber.intValue) else { return }
                playerItemStatus = status
            } else {
                playerItemStatus = .unknown
            }
            
            switch playerItemStatus {
            case .readyToPlay:
                guard isFirstPlaying else { return }
                
                delegate?.isPlayedFirst()
                isFirstPlaying = false
            case .failed:
                assertionFailure("PlayerItem failed.")
            case .unknown:
                assertionFailure("PlayerItem is not yet ready.")
            }
        }
    }
    
    // MARK: 재생 준비
    func prepareToPlay() {
        // PlayerItem 초기화
        let assetKeys = ["playable", "hasProtectedContent"]
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        playerItem.addObserver(self,
                               forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.old, .new],
                               context: &playerItemContext)
        
        // Player와 PlayerLayer 준비
        player.replaceCurrentItem(with: playerItem)
        playerLayer.videoGravity = .resizeAspectFill
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            self?.delegate?.setTimeObserverValue(time: time)
        })
    }
    
    private func removePeriodicTimeObserver() {
        guard let timeObserverToken = timeObserverToken else { return }
        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
    
    // MARK: 재생 관련
    func play() {
        player.play()
        
        delegate?.playerPlayed()
    }
    
    func pause() {
        player.pause()
        
        delegate?.playerPaused()
    }
    
    func changeTenSeconds(to direction: Direction) {
        let currentTimeSeconds = player.currentTime().seconds
        let timeToBeChanged: CMTime = {
            switch direction {
            case .back:
                return CMTime(seconds: currentTimeSeconds - 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            case .forward:
                return CMTime(seconds: currentTimeSeconds + 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            }
        }()
        
        player.seek(to: timeToBeChanged,
                    toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [weak self] _ in
            guard let isPlaying = self?.player.isPlaying else { return }
            switch isPlaying {
            case true:
                self?.play()
            case false:
                self?.pause()
            }
        }
    }
    
    // MARK: TimeSlier ValueChanged 관련
    func stopPlayingAndSeekSmoothlyToTime(newChaseTime: CMTime) {
        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime
            
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
        player.seek(to: seekTimeInProgress,
                    toleranceBefore: kCMTimeZero,
                    toleranceAfter: kCMTimeZero) { [weak self] isFinished in
                        guard let strongSelf = self else { return }
                        if CMTimeCompare(seekTimeInProgress, strongSelf.chaseTime) == 0 {
                            strongSelf.isSeekInProgress = false
                        } else {
                            strongSelf.trySeekToChaseTime()
                        }
                        
                        guard let isPlaying = self?.player.isPlaying else { return }
                        switch isPlaying {
                        case true:
                            self?.play()
                        case false:
                            self?.pause()
                        }
        }
    }
}
