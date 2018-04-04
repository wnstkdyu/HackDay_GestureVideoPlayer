//
//  PlayerView.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 3..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVKit

class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        guard let playerLayer = layer as? AVPlayerLayer else {
            return AVPlayerLayer()
        }
        
        return playerLayer
    }
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
