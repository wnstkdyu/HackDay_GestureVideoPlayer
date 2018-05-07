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

class PlayerViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var playerView: PlayerView!
    @IBOutlet weak var mediaSelectionTableView: UITableView!
    
    @IBOutlet weak var tapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet weak var doubleTapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: Public Properties
    public var playerManager: PlayerManager?
    
    // MARK: Private Properties
    private var isVisible: Bool = true
    private var isLocked: Bool = false
    private var workItemArray: [DispatchWorkItem] = []
    
    private var newCMTime: CMTime?
    private var firstBrightness: CGFloat?
    private var firstVolume: Float?
    
    private var mediaSelectionDataSource = MediaSelectionDataSource()
    
    // MARK: Rotation Properties
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscape]
    }
    
    // MARK: LifeCycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerManager?.delegate = self
        playerView.delegate = self
        
        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        mediaSelectionTableView.rowHeight = mediaSelectionTableView.frame.height / 3
        mediaSelectionTableView.dataSource = mediaSelectionDataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        playerView.hideUI()
        playerView.changeToLandscape()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setUpPlayback()
    }
    
    // MARK: Setup Methods
    private func setUpPlayback() {
        playerManager?.prepareToPlay()
        
        // PlayerView에서 준비할 것들.
        playerManager?.playerLayer.frame = playerView.frame
        
        guard let asset = playerManager?.asset else { return }
        playerView.setPlayerUI(asset: asset)
        getSubtitleInfo(asset: asset)
        
        guard let playerLayer = playerManager?.playerLayer else { return }
        playerView.layer.sublayers?.insert(playerLayer, at: 0)
    }
    
    private func getSubtitleInfo(asset: AVAsset) {
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            for option in group.options {
                switch option.displayName {
                case "Korean":
                    mediaSelectionDataSource.subtitlesArray.append((.korean, false))
                case "English":
                    mediaSelectionDataSource.subtitlesArray.append((.english, false))
                default:
                    continue
                }
            }
        }
        
        mediaSelectionDataSource.subtitlesArray.append((.none, true))
    }
    
    // MARK: IBAction Methods
    @IBAction func handleTapGesture(_ sender: UITapGestureRecognizer) {
        workItemArray.forEach { $0.cancel() }
        hideMediaSelectionTableView()
        
        if isVisible {
            playerView.fadeOutUI(isLocked: isLocked)
        } else {
            playerView.fadeInUI(isLocked: isLocked)
        }
    }
    
    @IBAction func handleDoubleTapGesture(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1.0 {
            scrollView.setZoomScale(1.5, animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }
    
    @IBAction func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            playerView.centerTimeLabel.isHidden = false
            firstBrightness = UIScreen.main.brightness
            firstVolume = playerManager?.player.volume
            
            view.addSubview(playerView.expandingView)
        case .changed:
            let translation = sender.translation(in: playerView)
            let xRatio = translation.x / playerView.frame.width
            let yRatio = translation.y / playerView.frame.height
            
            if abs(xRatio) > abs(yRatio) {
                // 좌우로 움직임
                let ratio = Double(xRatio)
                
                guard let currentTimeSeconds = playerManager?.player.currentTime().seconds,
                    let assetDuration = playerManager?.player.currentItem?.duration.seconds else { return }
                var newSeconds = currentTimeSeconds + assetDuration * ratio
                if newSeconds > assetDuration {
                    newSeconds = assetDuration
                }
                newCMTime = CMTime(seconds: newSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
                playerView.centerTimeLabel.text = newCMTime?.toTimeForamt
            } else {
                // 상하로 움직임 -> 화면을 반으로 갈라 왼쪽은 밝기, 오른쪽은 볼륨 조절
                if sender.location(in: playerView).x <= playerView.frame.width / 2 {
                    // 왼쪽: 밝기
                    guard let firstBrightness = firstBrightness else { return }
                    UIScreen.main.brightness = CGFloat(firstBrightness) - yRatio
                    
                    playerView.expandingView.frame.origin = CGPoint(x: 0, y: playerView.frame.height * (1 - UIScreen.main.brightness))
                } else {
                    // 오른쪽: 볼륨
                    guard let firstVolume = firstVolume else { return }
                    playerManager?.player.volume = firstVolume - Float(yRatio)
                    
                    playerView.expandingView.frame.origin = CGPoint(x: playerView.frame.width / 2, y: playerView.frame.height * CGFloat(1 - (firstVolume - Float(yRatio))))
                    if playerView.expandingView.frame.origin.y < 0 {
                        playerView.expandingView.frame.origin.y = 0
                    }
                }
            }
        case .ended:
            if let newCMTime = newCMTime {
                playerManager?.player.seek(to: newCMTime,
                             toleranceBefore: kCMTimeZero,
                             toleranceAfter: kCMTimeZero) { [weak self] _ in
                                guard let isPlaying = self?.playerManager?.player.isPlaying else { return }
                                switch isPlaying {
                                case true:
                                    self?.playerManager?.play()
                                case false:
                                    self?.playerManager?.pause()
                                }
                }
            }
            newCMTime = nil
            firstBrightness = nil
            firstVolume = nil
            
            playerView.centerTimeLabel.text = nil
            playerView.centerTimeLabel.isHidden = true
            
            playerView.expandingView.frame.origin = CGPoint(x: 0, y: playerView.frame.maxY)
            playerView.expandingView.removeFromSuperview()
        default:
            break
        }
    }
    
    // MARK: TableView UI Methods
    private func showMediaSelectionTableView() {
        playerView.outletCollection.forEach { $0.isHidden = true }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let tableViewFrame = self?.mediaSelectionTableView.frame,
                let viewHeight = self?.view.frame.height else { return }
            self?.mediaSelectionTableView.frame.origin.y = viewHeight - tableViewFrame.height
        }
    }
    
    private func hideMediaSelectionTableView() {
        playerView.outletCollection.forEach { $0.isHidden = false }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let viewHeight = self?.view.frame.height else { return }
            self?.mediaSelectionTableView.frame.origin.y = viewHeight
        }
    }
}

extension PlayerViewController: PlayerManagerDelegate {
    // MARK: PlayerManagerDelegate Methods
    func isPlayedFirst() {
        playerView.showUI()
        playerManager?.play()
    }
    
    func setTimeObserverValue(time: CMTime) {
        playerView.currentTimeLabel.text = time.seconds.toTimeFormat
        
        let timeSliderMaximumValue = playerView.timeSlider.maximumValue
        guard let assetDuration = playerManager?.player.currentItem?.duration.seconds else { return }
        let value = timeSliderMaximumValue * Float(time.seconds / assetDuration)
        playerView.timeSlider.setValue(value, animated: true)
    }
    
    func playerPlayed() {
        playerView.playButton.setState(playState: .play)
        
        guard isVisible else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.playerView.fadeOutUI()
        }
        
        workItemArray.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    func playerPaused() {
        playerView.playButton.setState(playState: .pause)
        
        guard isVisible else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.playerView.fadeOutUI()
        }
        workItemArray.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    func playerEnded() {
        playerView.playButton.setState(playState: .replay)
        
        guard isVisible else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.playerView.fadeOutUI()
        }
        
        workItemArray.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
}

extension PlayerViewController: PlayerViewDelegate {
    // MARK: PlayerViewDelegate Methods
    func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    func playButtonTapped(beforeState: PlayState) {
        switch beforeState {
        case .play:
            playerManager?.pause()
        case .pause:
            playerManager?.play()
        case .replay:
            playerManager?.replay()
        }
    }
    
    func backwardButtonTapped() {
        playerManager?.changeTenSeconds(to: .backward)
    }
    
    func forwardButtonTapped() {
        playerManager?.changeTenSeconds(to: .forward)
    }
    
    func timeSliderValueChanged(value: Float) {
        let valueRatio = value / playerView.timeSlider.maximumValue
        
        guard let totoalSeconds = playerManager?.player.currentItem?.duration.seconds else { return }
        let currentTimeSeconds = Double(valueRatio) * totoalSeconds
        let timeToBeChanged = CMTime(seconds: currentTimeSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        playerManager?.stopPlayingAndSeekSmoothlyToTime(newChaseTime: timeToBeChanged)
    }
    
    func subtitleButtonTapped() {
        mediaSelectionDataSource.setSubtitleDataSource()
        mediaSelectionTableView.reloadData()
        
        showMediaSelectionTableView()
    }
    
    func resolutionButtonTapped() {
        mediaSelectionDataSource.setResolutionDataSource()
        mediaSelectionTableView.reloadData()
        
        showMediaSelectionTableView()
    }
    
    func isVisibleChange(to isVisible: Bool) {
        self.isVisible = isVisible
    }
    
    func checkLockButton() {
        playerView.fadeOutUI(isLocked: isLocked)
    }
    
    func setLock(isLocked: Bool) {
        self.isLocked = isLocked
        workItemArray.forEach { $0.cancel() }
    }
}

extension PlayerViewController: UIGestureRecognizerDelegate {
    // MARK: UIGestureRecognizerDelegate Methods
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {

        guard let touchView = touch.view,
            touchView.isDescendant(of: view) else { return false }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension PlayerViewController: UIScrollViewDelegate {
    // MARK: UIScrollViewDelegate Methods
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return playerView
    }
}

extension PlayerViewController: UITableViewDelegate {
    // MARK: UITableViewDelegate Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.accessoryType = .checkmark
        
        switch mediaSelectionDataSource.isSubtitle {
        case true:
            for i in mediaSelectionDataSource.subtitlesArray.indices {
                let subtitleInfo = mediaSelectionDataSource.subtitlesArray[i]
                if i == indexPath.row {
                    mediaSelectionDataSource.subtitlesArray[i] = (subtitleInfo.0, true)
                    
                    if let group = playerManager?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                        guard let locale = subtitleInfo.0.getLocale() else { return }
                        let options = AVMediaSelectionGroup.mediaSelectionOptions(from: group.options, with: locale)
                        if let option = options.first {
                            playerManager?.player.currentItem?.select(option, in: group)
                        }
                    }
                } else {
                    mediaSelectionDataSource.subtitlesArray[i] = (subtitleInfo.0, false)
                }
            }
            break
        case false:
            guard let playerItem = playerManager?.player.currentItem else { return }
            
            for i in mediaSelectionDataSource.resolutionsArray.indices {
                let resolutionInfo = mediaSelectionDataSource.resolutionsArray[i]
                if i == indexPath.row {
                    mediaSelectionDataSource.resolutionsArray[i] = (resolutionInfo.0, true)
                    playerItem.preferredPeakBitRate = resolutionInfo.0.getPreferredBitRate()
                } else {
                    mediaSelectionDataSource.resolutionsArray[i] = (resolutionInfo.0, false)
                }
            }
        }
        
        tableView.reloadData()
        
        hideMediaSelectionTableView()
    }
}
