//
//  Enum.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 30..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit

public enum Subtitle: String {
    case korean = "Korean"
    case english = "English"
    case none = "자막 없음"
    
    func getLocale() -> Locale? {
        switch self {
        case .korean:
            return Locale(identifier: "ko-KR")
        case .english:
            return Locale(identifier: "en-US")
        case .none:
            return nil
        }
    }
}

public enum Resolution: String {
    case high = "1080P"
    case normal = "720P"
    case low = "360P"
    
    func getPreferredBitRate() -> Double {
        switch self {
        case .high:
            return 11000
        case .normal:
            return 4500
        case .low:
            return 600
        }
    }
}

public enum PlayState {
    case play
    case pause
    case replay
    
    func getImage() -> UIImage {
        switch self {
        case .play:
            return #imageLiteral(resourceName: "ic_pause_white_48pt")
        case .pause:
            return #imageLiteral(resourceName: "ic_play_arrow_white_48pt")
        case .replay:
            return #imageLiteral(resourceName: "ic_replay_white_48pt")
        }
    }
}

public enum Direction {
    case backward
    case forward
}

public enum UIVisibleState {
    case appeared
    case disappeared
    case appearing
    case disappearing
}
