//
//  ViewController.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 3..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ViewController: UIViewController {
    
    private var player: AVPlayer?
    private var timeObserverToken: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func playVideo(_ sender: UIButton) {
        guard let url = URL(string: "https://devimages-cdn.apple.com/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8") else { return }
        
        // Create an AVPlayer, passing it the HTTP Live Streaming URL.
        player = AVPlayer(url: url)
        
        // Create a new AVPlayerViewController and pass it a reference to the player.
        let controller = AVPlayerViewController()
        controller.player = player
        
        // Modally present the player and call the player's play() method when complete.
        present(controller, animated: true) { [weak self] in
            self?.player?.play()
        }
    }
    
    private func createAsset() {
        guard let url = URL(string: "https://devimages-cdn.apple.com/samplecode/avfoundationMedia/AVFoundationQueuePlayer_HLS2/master.m3u8") else { return }
//        let asset = AVAsset(url: url)
        // 또는
        let asset = AVURLAsset(url: url, options: [AVURLAssetAllowsCellularAccessKey: false])
        let playableKey = "playable"
        
        // Load the "playable" property
        // 백그라운드 큐에서 돌아가기 때문에 UI작업은 main queue로 돌아와 해줘야 함.
        asset.loadValuesAsynchronously(forKeys: [playableKey]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: playableKey, error: &error)
            switch status {
            case .loaded:
                // Sucessfully loaded. Continue processing.
                print("loading asset property succeeded")
            case .failed:
                // Handle error.
                print("loading asset property failed")
            case .cancelled:
                // Terminate processing
                print("loading asset property cancelled")
            default:
                // Handle all other cases
                break
            }
        }
    }
    
    func addPeriodicTimeObserver() {
        // Invoke callback every half second
        let interval = CMTime(seconds: 0.5,
                              preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Queue on which to invoke the callback
        let mainQueue = DispatchQueue.main
        // Add time observer
        timeObserverToken =
            player?.addPeriodicTimeObserver(forInterval: interval, queue: mainQueue) {
                [weak self] time in
                // update player transport UI
        }
    }
}

