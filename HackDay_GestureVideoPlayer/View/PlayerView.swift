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
    
    func isVisibleChange(to isVisible: Bool)
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
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .white)
        activityIndicator.frame = CGRect(origin: self.center, size: CGSize(width: 40, height: 40))
        
        return activityIndicator
    }()
    
    lazy var expandingView: UIView = {
        let expandingView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: self.frame.width / 2, height: self.frame.height)))
        expandingView.backgroundColor = currentTimeLabel.textColor
        expandingView.alpha = 0.5
        
        return expandingView
    }()
    
    weak var delegate: PlayerViewDelegate?
    
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
    
    func changeToLandscape() {
        let orientationValue = UIDeviceOrientation.landscapeRight.rawValue
        UIDevice.current.setValue(orientationValue, forKey: "orientation")
    }
    
    func setPlayerUI(asset: AVAsset) {
        totalTimeLabel.text = asset.duration.toTimeForamt
        if asset.duration.seconds / 3600 > 0 {
            currentTimeLabel.text = "00:00:00"
        } else {
            currentTimeLabel.text = "00:00"
        }
    }
    
    func showUI() {
        outletCollection.filter { $0 != backButton }
            .forEach { $0.isHidden = false }
        hideActivityIndicator()
    }
    
    func hideUI() {
        outletCollection.filter { $0 != backButton }
            .forEach { $0.isHidden = true }
        showActivityIndicator()
        
//        delegate?.isVisibleChange(to: false)
    }
    
    func showActivityIndicator() {
        guard !activityIndicator.isDescendant(of: self) else {
            activityIndicator.startAnimating()
            
            return
        }
        
        self.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        activityIndicator.stopAnimating()
    }
    
    func fadeInUI(isLocked: Bool = false) {
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
                                    self?.delegate?.isVisibleChange(to: false)
                            })
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
                    }
                    guard outlet == self?.outletCollection.last else { return }
                    self?.delegate?.isVisibleChange(to: true)
                    
                    // isLocked일 경우 lockButton도 사라져야 함.
                    let workItem = DispatchWorkItem {
                        self?.delegate?.checkLockButton()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
                })
        }
    }
    
    func fadeOutUI(isLocked: Bool = false) {
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
                                    self?.delegate?.isVisibleChange(to: false)
                            })
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: workItem)
                    }
                    guard outlet == self?.outletCollection.last else { return }
                    
                    self?.delegate?.isVisibleChange(to: false)
                })
        }
    }
    
    func setLockUI(isLocked: Bool) {
        delegate?.setLock(isLocked: isLocked)
        
        switch isLocked {
        case true:
            fadeOutUI(isLocked: true)
        case false:
            fadeInUI(isLocked: false)
        }
    }
}
