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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var playerView: UIView!
    @IBOutlet var outletCollection: [UIView]!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var qualityLabel: UILabel!
    
    @IBOutlet weak var centerTimeLabel: UILabel!
    
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.frame = CGRect(origin: playerView.center, size: CGSize(width: 40, height: 40))
        
        return activityIndicator
    }()
    
    private lazy var expandingView: UIView = {
        let expandingView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: playerView.frame.width / 2, height: playerView.frame.height)))
        expandingView.backgroundColor = currentTimeLabel.textColor
        expandingView.alpha = 0.5
        
        return expandingView
    }()
    
    var asset: AVAsset?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    private var playerItemContext = 0
    private var playerItemStatus: AVPlayerItemStatus = .unknown
    private var timeObserverToken: Any?
    
    private var chaseTime: CMTime = kCMTimeZero
    private var isSeekInProgress: Bool = false
    
    private var isFirstPlaying: Bool = true
    private var isVisible: Bool = true
    private var isLocked: Bool = false
    private var workItemArray: [DispatchWorkItem] = []
    
    private var newCMTime: CMTime?
    private var firstBrightness: CGFloat?
    private var firstVolume: Float?
    
    // 화면 회전관련 변수 오버라이드
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscape]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideUI()
        changeToLandscape()
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

                showUI()
                play()
                
                isFirstPlaying = false
            case .failed:
                print("PlayerItem failed.")
            case .unknown:
                print("PlayerItem is not yet ready.")
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
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
        
        stopPlayingAndSeekSmoothlyToTime(newChaseTime: timeToBeChanged)
    }
    
    @IBAction func handleTapGesture(_ sender: UITapGestureRecognizer) {
        workItemArray.forEach { $0.cancel() }
        
        if isVisible {
            fadeOutUI(isLocked: isLocked)
        } else {
            fadeInUI(isLocked: isLocked)
        }
    }
    
    @IBAction func handleDoubleTapGesture(_ sender: UITapGestureRecognizer) {
        print(scrollView.zoomScale)
        
        if scrollView.zoomScale == 1.0 {
            scrollView.setZoomScale(1.5, animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    @IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            centerTimeLabel.isHidden = false
            firstBrightness = UIScreen.main.brightness
            firstVolume = player?.volume
            
            view.addSubview(expandingView)
        case .changed:
            let translation = sender.translation(in: playerView)
            let xRatio = translation.x / playerView.frame.width
            let yRatio = translation.y / playerView.frame.height
            
            if abs(xRatio) > abs(yRatio) {
                // 좌우로 움직임
                let ratio = Double(xRatio)
                
                guard let currentTimeSeconds = player?.currentTime().seconds,
                    let assetDuration = player?.currentItem?.duration.seconds else { return }
                var newSeconds = currentTimeSeconds + assetDuration * ratio
                if newSeconds > assetDuration {
                    newSeconds = assetDuration
                }
                newCMTime  = CMTime(seconds: newSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                centerTimeLabel.text = newCMTime?.toTimeForamt
            } else {
                // 상하로 움직임 -> 화면을 반으로 갈라 왼쪽은 밝기, 오른쪽은 볼륨 조절
                if sender.location(in: playerView).x <= playerView.frame.width / 2 {
                    // 왼쪽: 밝기
                    guard let firstBrightness = firstBrightness else { return }
                    UIScreen.main.brightness = CGFloat(firstBrightness) - yRatio
                    
                    expandingView.frame.origin = CGPoint(x: 0, y: playerView.frame.height * (1 - UIScreen.main.brightness))
                } else {
                    // 오른쪽: 볼륨
                    guard let firstVolume = firstVolume else { return }
                    player?.volume = firstVolume - Float(yRatio)
                    
                    expandingView.frame.origin = CGPoint(x: playerView.frame.width / 2, y: playerView.frame.height * CGFloat(1 - (firstVolume - Float(yRatio))))
                    if expandingView.frame.origin.y < 0 {
                        expandingView.frame.origin.y = 0
                    }
                }
            }
        case .ended:
            if let newCMTime = newCMTime {
                player?.seek(to: newCMTime,
                             toleranceBefore: kCMTimeZero,
                             toleranceAfter: kCMTimeZero) { [weak self] _ in
                                guard let isPlaying = self?.player?.isPlaying else { return }
                                switch isPlaying {
                                case true:
                                    self?.play()
                                case false:
                                    self?.pause()
                                }
                }
            }
            newCMTime = nil
            firstBrightness = nil
            firstVolume = nil
            
            centerTimeLabel.text = nil
            centerTimeLabel.isHidden = true
            
            expandingView.frame.origin = CGPoint(x: 0, y: playerView.frame.maxY)
            expandingView.removeFromSuperview()
        default:
            break
        }
    }
    
    private func changeToLandscape() {
            let orientationValue = UIDeviceOrientation.landscapeRight.rawValue
            UIDevice.current.setValue(orientationValue, forKey: "orientation")
    }
    
    private func setPlayerUI(asset: AVAsset) {
        totalTimeLabel.text = asset.duration.toTimeForamt
        if asset.duration.seconds / 3600 > 0 {
            currentTimeLabel.text = "00:00:00"
        } else {
            currentTimeLabel.text = "00:00"
        }
    }
    
    private func showUI() {
        outletCollection.filter { $0 != backButton}
            .forEach { $0.isHidden = false }
        hideActivityIndicator()
    }
    
    private func hideUI() {
        outletCollection.filter { $0 != backButton }
            .forEach { $0.isHidden = true }
        showActivityIndicator()
    }
    
    private func showActivityIndicator() {
        guard !activityIndicator.isDescendant(of: self.playerView) else {
            activityIndicator.startAnimating()
            
            return
        }
        
        self.playerView.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }
    
    private func fadeInUI(isLocked: Bool = false) {
        outletCollection.filter { isLocked ? $0 == lockButton : true }
            .forEach { outlet in
                UIView.animate(withDuration: 1.0,
                               delay: 0.0,
                               options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
                               animations: {
                                outlet.alpha = 1.0
                }, completion: { [weak self] _ in
                    if isLocked {
                        let workItem = DispatchWorkItem {
                            UIView.animate(withDuration: 1.0,
                                           animations: { [weak self] in
                                            self?.lockButton.alpha = 0.0
                            }, completion: { [weak self] _ in
                                    self?.isVisible = false
                            })
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
                    }
                    guard outlet == self?.outletCollection.last else { return }
                    self?.isVisible = true
                    
                    // isLocked일 경우 isLocked도 사라져야 함.
                    let workItem = DispatchWorkItem {
                        guard let strongSelf = self else { return }
                        self?.fadeOutUI(isLocked: strongSelf.isLocked)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
                })
        }
    }
    
    @objc private func fadeOutUI(isLocked: Bool = false) {
        outletCollection.filter { isLocked ? $0 != lockButton : true }
            .forEach { outlet in
                UIView.animate(withDuration: 1.0,
                               delay: 0.0,
                               options: [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState],
                               animations: {
                                outlet.alpha = 0.0
                }, completion: { [weak self] _ in
                    if isLocked {
                        let workItem = DispatchWorkItem {
                            UIView.animate(withDuration: 1.0,
                                           animations: { [weak self] in
                                            self?.lockButton.alpha = 0.0
                            }, completion: { [weak self] _ in
                                    self?.isVisible = false
                            })
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
                    }
                    guard outlet == self?.outletCollection.last else { return }
                    
                    self?.isVisible = false
                })
        }
    }
    
    private func setLockUI(isLocked: Bool) {
        self.isLocked = isLocked
        print(self.isLocked)
        
        workItemArray.forEach { $0.cancel() }
        switch isLocked {
        case true:
            fadeOutUI(isLocked: true)
        case false:
            fadeInUI(isLocked: false)
        }
    }
    
    private func prepareToPlay() {
        guard let asset = asset else { return }
        
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
        
        guard isVisible else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.fadeOutUI()
        }
        workItemArray.append(workItem)
        workItem.notify(queue: .main) {
            
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    private func pause() {
        playButton.isSelected = false
        
        player?.pause()
        
        guard isVisible else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.fadeOutUI()
        }
        workItemArray.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
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
                     toleranceBefore: kCMTimeZero,
                     toleranceAfter: kCMTimeZero) { [weak self] isFinished in
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

extension PlayerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        guard let touchView = touch.view,
            touchView.isDescendant(of: view) else { return false }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension PlayerViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return playerView
    }
}
