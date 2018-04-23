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
    @IBOutlet weak var mediaSelectionTableView: UITableView!
    @IBOutlet var outletCollection: [UIView]!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var subtitleButton: UIButton!
    @IBOutlet weak var resolutionButton: UIButton!
    
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
    
    // PlayerManager
    var playerManager: PlayerManager?
    
    private var isVisible: Bool = true
    private var isLocked: Bool = false
    private var workItemArray: [DispatchWorkItem] = []
    
    private var newCMTime: CMTime?
    private var firstBrightness: CGFloat?
    private var firstVolume: Float?
    
    private var mediaSelectionDataSource = MediaSelectionDataSource()
    
    // 화면 회전관련 변수 오버라이드
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.landscape]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerManager?.delegate = self
        
        tapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        
        mediaSelectionTableView.rowHeight = mediaSelectionTableView.frame.height / 3
        mediaSelectionTableView.dataSource = mediaSelectionDataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hideUI()
        changeToLandscape()
    }
    
    // 화면 크기가 다 결정되고 나서 해야 비디오가 꽉 차게 나옴.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        playerManager?.prepareToPlay()
        // PlayerView에서 준비할 것들.
        playerManager?.playerLayer.frame = playerView.frame
        
        guard let asset = playerManager?.asset else { return }
        setPlayerUI(asset: asset)
        getSubtitleInfo(asset: asset)

        guard let playerLayer = playerManager?.playerLayer else { return }
        playerView.layer.addSublayer(playerLayer)
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        switch sender.isSelected {
        case true:
            playerManager?.pause()
        case false:
            playerManager?.play()
        }
    }
    
    @IBAction func replayButtonTapped(_ sender: UIButton) {
        playerManager?.changeTenSeconds(to: .back)
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        playerManager?.changeTenSeconds(to: .forward)
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
        
        guard let totoalSeconds = playerManager?.player.currentItem?.duration.seconds else { return }
        let currentTimeSeconds = Double(valueRatio) * totoalSeconds
        let timeToBeChanged = CMTime(seconds: currentTimeSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        playerManager?.stopPlayingAndSeekSmoothlyToTime(newChaseTime: timeToBeChanged)
    }
    
    @IBAction func subtitleButtonTapped(_ sender: UIButton) {
        mediaSelectionDataSource.setSubtitleDataSource()
        mediaSelectionTableView.reloadData()
        
        showMediaSelectionTableView()
    }
    
    @IBAction func resolutionButtonTapped(_ sender: UIButton) {
        mediaSelectionDataSource.setResolutionDataSource()
        mediaSelectionTableView.reloadData()
        
        showMediaSelectionTableView()
    }
    
    @IBAction func handleTapGesture(_ sender: UITapGestureRecognizer) {
        workItemArray.forEach { $0.cancel() }
        hideMediaSelectionTableView()
        
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
            firstVolume = playerManager?.player.volume
            
            view.addSubview(expandingView)
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
                    playerManager?.player.volume = firstVolume - Float(yRatio)
                    
                    expandingView.frame.origin = CGPoint(x: playerView.frame.width / 2, y: playerView.frame.height * CGFloat(1 - (firstVolume - Float(yRatio))))
                    if expandingView.frame.origin.y < 0 {
                        expandingView.frame.origin.y = 0
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
    
    private func showUI() {
        outletCollection.filter { $0 != backButton }
            .forEach { $0.isHidden = false }
        hideActivityIndicator()
    }
    
    private func hideUI() {
        outletCollection.filter { $0 != backButton }
            .forEach { $0.isHidden = true }
        showActivityIndicator()
    }
    
    private func showMediaSelectionTableView() {
        outletCollection.forEach { $0.isHidden = true }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let tableViewFrame = self?.mediaSelectionTableView.frame,
                let viewHeight = self?.view.frame.height else { return }
            self?.mediaSelectionTableView.frame.origin.y = viewHeight - tableViewFrame.height
        }
    }
    
    private func hideMediaSelectionTableView() {
        outletCollection.forEach { $0.isHidden = false }
        
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let viewHeight = self?.view.frame.height else { return }
            self?.mediaSelectionTableView.frame.origin.y = viewHeight
        }
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
}

extension PlayerViewController: PlayerManagerDelegate {
    func isPlayedFirst() {
        showUI()
        playerManager?.play()
    }
    
    func setTimeObserverValue(time: CMTime) {
        currentTimeLabel.text = time.seconds.toTimeFormat
        
        let timeSliderMaximumValue = timeSlider.maximumValue
        guard let assetDuration = playerManager?.player.currentItem?.duration.seconds else { return }
        let value = timeSliderMaximumValue * Float(time.seconds / assetDuration)
        timeSlider.setValue(value, animated: true)
    }
    
    func playerPlayed() {
        playButton.isSelected = true
        
        guard isVisible else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.fadeOutUI()
        }
        
        workItemArray.append(workItem)
        workItem.notify(queue: .main) {
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
    }
    
    func playerPaused() {
        playButton.isSelected = false
        
        guard isVisible else { return }
        let workItem = DispatchWorkItem { [weak self] in
            self?.fadeOutUI()
        }
        workItemArray.append(workItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
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

extension PlayerViewController: UITableViewDelegate {
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
