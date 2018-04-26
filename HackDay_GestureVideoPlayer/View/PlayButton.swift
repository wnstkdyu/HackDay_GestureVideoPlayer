//
//  PlayButton.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 26..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit

enum PlayState {
    case play
    case pause
    case replay
    
    func getImage() -> UIImage {
        switch self {
        case .play:
            return #imageLiteral(resourceName: "ic_play_arrow_white_48pt")
        case .pause:
            return #imageLiteral(resourceName: "ic_pause_white_48pt")
        case .replay:
            return #imageLiteral(resourceName: "ic_replay_white_48pt")
        }
    }
}

class PlayButton: UIButton {
    var playState: PlayState = .play
    
    func setState(playState: PlayState) {
        self.imageView?.image = playState.getImage()
    }
}
