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
    func playerEnded()
}

class PlayerManager: NSObject {
    // MARK: Public Properties
    public weak var delegate: PlayerManagerDelegate?
    
    public var asset: AVAsset
    public var player: AVPlayer
    public var playerLayer: AVPlayerLayer
    
    // MARK: Private Properties
    private var playerItemContext = 0
    private var playerItemStatus: AVPlayerItemStatus = .unknown
    private var isFirstPlaying: Bool = true
    
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
        removePlayerItemObserver()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
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
                player.currentItem?.preferredPeakBitRate = 0
                
                delegate?.isPlayedFirst()
                isFirstPlaying = false
            case .failed:
                assertionFailure("PlayerItem failed.")
            case .unknown:
                assertionFailure("PlayerItem is not yet ready.")
            }
        }
    }
    
    // MARK: Prepare Playback
    public func prepareToPlay() {
        // PlayerItem 초기화
        let assetKeys = ["playable", "hasProtectedContent"]
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: assetKeys)
        
        playerItem.addObserver(self,
                               forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.old, .new],
                               context: &playerItemContext)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceivePlayerItmeEnded), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        // 처음에 제한을 두고 재생시작하면 풀기
        playerItem.preferredPeakBitRate = 2000
        
        // Player와 PlayerLayer 준비
        // replaceCurrentItem(with:)으로 하면 playback이 더 빨리 세팅됨.
        // https://developer.apple.com/videos/play/wwdc2016/503/
        player.replaceCurrentItem(with: playerItem)
        playerLayer.videoGravity = .resizeAspect
        
        addPeriodicTimeObserver()
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main, using: { [weak self] time in
            guard let strongSelf = self else { return }
            
            strongSelf.delegate?.setTimeObserverValue(time: time)
        })
    }
    
    private func removePeriodicTimeObserver() {
        guard let timeObserverToken = timeObserverToken else { return }
        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
    
    private func removePlayerItemObserver() {
        player.currentItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext)
    }
    
    @objc private func didReceivePlayerItmeEnded() {
        delegate?.playerEnded()
    }
    
    // MARK: Playback Method
    public func play() {
        player.play()
        
        delegate?.playerPlayed()
    }
    
    public func pause() {
        player.pause()
        
        delegate?.playerPaused()
    }
    
    public func replay() {
        player.seek(to: kCMTimeZero)
        
        play()
    }
    
    public func changeTenSeconds(to direction: PlayerDirection) {
        let currentTimeSeconds = player.currentTime().seconds
        let tenSeconds: Double = 10.0
        let timeToBeChanged: CMTime = {
            switch direction {
            case .backward:
                return CMTime(seconds: currentTimeSeconds - tenSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            case .forward:
                return CMTime(seconds: currentTimeSeconds + tenSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            }
        }()
        
        player.seek(to: timeToBeChanged) { [weak self] _ in
            guard let strongSelf = self else { return }
            
            strongSelf.player.isPlaying ? strongSelf.play() : strongSelf.pause()
        }
    }
    
    // MARK: TimeSlider ValueChanged
    public func stopPlayingAndSeekSmoothlyToTime(newChaseTime: CMTime) {
        guard CMTimeCompare(newChaseTime, chaseTime) != 0 else { return }
        
        chaseTime = newChaseTime
        guard !isSeekInProgress else { return }
        trySeekToChaseTime()
    }
    
    private func trySeekToChaseTime() {
        guard playerItemStatus == .readyToPlay else { return }
        actuallySeekToTime()
    }
    
    private func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        
        player.seek(to: seekTimeInProgress) { [weak self] _ in
            guard let strongSelf = self else { return }
            
            if CMTimeCompare(seekTimeInProgress, strongSelf.chaseTime) == 0 {
                strongSelf.isSeekInProgress = false
            } else {
                strongSelf.trySeekToChaseTime()
            }
            
            guard let isPlaying = self?.player.isPlaying else { return }
            isPlaying ? strongSelf.play() : strongSelf.pause()
        }
    }
}
