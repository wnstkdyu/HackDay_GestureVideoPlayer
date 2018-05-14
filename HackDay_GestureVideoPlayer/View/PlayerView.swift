//
//  PlayerView.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 23..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVFoundation

protocol PlayerViewDelegate: class {
    func backButtonTapped()
    func playButtonTapped(beforeState: PlayState)
    func backwardButtonTapped()
    func forwardButtonTapped()
    func timeSliderValueChanged(value: Float)
    func subtitleButtonTapped()
    func resolutionButtonTapped()
    
    func uiVisibleStateChange(to uiVisibleState: UIVisibleState)
    func checkLockButton()
    func setLock(isLocked: Bool)
}

class PlayerView: UIView {
    @IBOutlet var outletCollection: [UIView]!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var playButton: PlayButton!
    @IBOutlet weak var lockButton: UIButton!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var totalTimeLabel: UILabel!
    @IBOutlet weak var subtitleButton: UIButton!
    @IBOutlet weak var resolutionButton: UIButton!
    @IBOutlet weak var centerTimeLabel: UILabel!
    
    // MARK: Public Properties
    public weak var delegate: PlayerViewDelegate?
    
    public lazy var expandingView: UIView = {
        let expandingView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.frame.width / 2, height: self.frame.height)))
        expandingView.backgroundColor = currentTimeLabel.textColor
        expandingView.alpha = 0.5
        
        return expandingView
    }()
    
    // MARK: Private Properties
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.frame = CGRect(origin: self.center, size: CGSize(width: 40, height: 40))
        
        return activityIndicator
    }()
    
    private let fadeDuration: TimeInterval = 0.5
    private let fadeInterval: TimeInterval = 3.0
    private var timer: Timer?
    
    // MARK: IBAction Methods
    @IBAction func backButtonTapped(_ sender: UIButton) {
        delegate?.backButtonTapped()
    }

    @IBAction func playButtonTapped(_ sender: PlayButton) {
        delegate?.playButtonTapped(beforeState: sender.playState)
    }
    
    @IBAction func backwardButtonTapped(_ sender: UIButton) {
        delegate?.backwardButtonTapped()
    }
    
    @IBAction func forwardButtonTapped(_ sender: UIButton) {
        delegate?.forwardButtonTapped()
    }
    
    @IBAction func lockButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        setLockUI(isLocked: sender.isSelected)
    }
    
    @IBAction func timeSliderValueChanged(_ sender: UISlider) {
        delegate?.timeSliderValueChanged(value: sender.value)
    }
    
    @IBAction func subtitleButtonTapped(_ sender: UIButton) {
        delegate?.subtitleButtonTapped()
    }
    
    @IBAction func resolutionButtonTapped(_ sender: UIButton) {
        delegate?.resolutionButtonTapped()
    }
    
    // MARK: Public Methods
    public func changeToLandscape() {
        let landscapeLeftOrientation = UIDeviceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(landscapeLeftOrientation, forKey: "orientation")
    }
    
    public func setPlayerUI(asset: AVAsset) {
        totalTimeLabel.text = asset.duration.toTimeFormat
        let secondsOfHour: Double = 3600
        
        if asset.duration.seconds / secondsOfHour > 0 {
            currentTimeLabel.text = "00:00:00"
        } else {
            currentTimeLabel.text = "00:00"
        }
    }
    
    public func showUI() {
        outletCollection.forEach { $0.isHidden = false }
        hideActivityIndicator()
    }
    
    public func hideUI() {
        outletCollection.forEach { $0.isHidden = true }
        showActivityIndicator()
    }
    
    public func fadeInUI(isLocked: Bool = false) {
        delegate?.uiVisibleStateChange(to: .appearing)
        
        outletCollection
            .filter {
                guard !isLocked else {
                    return $0 == lockButton
                }
                
                return true
            }
            .forEach { outlet in
                UIView.animate(withDuration: fadeDuration, delay: 0.0, options: [.allowUserInteraction], animations: {
                    outlet.alpha = 1.0
                }, completion: { [weak self] completed in
                    guard let strongSelf = self, completed else { return }
                    
                    guard !isLocked else {
                        strongSelf.delegate?.uiVisibleStateChange(to: .appeared)
                        strongSelf.setLockedTimer()
                        
                        return
                    }
                    
                    guard outlet == strongSelf.outletCollection.last else { return }
                    
                    strongSelf.delegate?.uiVisibleStateChange(to: .appeared)
                    strongSelf.setTimer(isLocked: isLocked)
                })
        }
    }
    
    public func fadeOutUI(isLocked: Bool = false) {
        outletCollection
            .filter {
                guard !isLocked else {
                    return $0 != lockButton
                }
                
                return true
            }
            .forEach { outlet in
                UIView.animate(withDuration: fadeDuration, delay: 0.0, options: [.allowUserInteraction], animations: {
                    outlet.alpha = 0.0
                }, completion: { [weak self] completed in
                    guard let strongSelf = self else { return }
                    
                    strongSelf.delegate?.uiVisibleStateChange(to: .disappearing)
                    guard completed else { return }
                    
                    guard outlet == strongSelf.outletCollection.last else { return }
                    strongSelf.delegate?.uiVisibleStateChange(to: .disappeared)
                    
                    guard isLocked else { return }
                    strongSelf.setLockedTimer()
                })
        }
    }
    
    public func cancelAllAnimations() {
        outletCollection.forEach { $0.layer.removeAllAnimations() }
        
        guard let timerIsValid = timer?.isValid,
            timerIsValid else { return }
        timer?.invalidate()
    }
    
    public func setTimer(isLocked: Bool) {
        timer = Timer.scheduledTimer(withTimeInterval: fadeInterval, repeats: false) { [weak self] _ in
            self?.fadeOutUI(isLocked: isLocked)
        }
    }
    
    public func setLockedTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: fadeInterval, repeats: false) { [weak self] _ in
            guard let strongSelf = self else { return }
            
            UIView.animate(withDuration: strongSelf.fadeDuration) {
                strongSelf.lockButton.alpha = 0.0
            }
        }
    }
    
    // MARK: Private Methods
    private func showActivityIndicator() {
        guard !activityIndicator.isDescendant(of: self) else {
            activityIndicator.startAnimating()
            
            return
        }
        
        self.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }
    
    private func setLockUI(isLocked: Bool) {
        delegate?.setLock(isLocked: isLocked)
        
        isLocked ? fadeOutUI(isLocked: true) : fadeInUI(isLocked: false)
    }
}
