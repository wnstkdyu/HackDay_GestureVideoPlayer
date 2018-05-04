//
//  PlayButton.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 26..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit

class PlayButton: UIButton {
    public var playState: PlayState = .play
    
    public func setState(playState: PlayState) {
        self.playState = playState
        
        setImage(playState.getImage(), for: .normal)
    }
}
