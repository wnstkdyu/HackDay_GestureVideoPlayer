//
//  MediaSelectionDataSource.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 14..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

enum Subtitle: String {
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

enum Resolution: String {
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

import UIKit

class MediaSelectionDataSource: NSObject, UITableViewDataSource {
    
    var subtitlesArray: [(Subtitle, Bool)] = []
    var resolutionsArray: [(Resolution, Bool)] = [(.high, true), (.normal, false), (.low, false)]
    
    var isSubtitle: Bool = true
    
    private let cellIdentifier = "MediaSelectionCell"
    
    func setSubtitleDataSource() {
        isSubtitle = true
    }
    
    func setResolutionDataSource() {
        isSubtitle = false
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch isSubtitle {
        case true:
            return subtitlesArray.count
        case false:
            return resolutionsArray.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        switch isSubtitle {
        case true:
            let subtitleData = subtitlesArray[indexPath.row]
            cell.textLabel?.text = subtitleData.0.rawValue
            
            if subtitleData.1 {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        case false:
            let resolutionData = resolutionsArray[indexPath.row]
            cell.textLabel?.text = resolutionData.0.rawValue
            
            if resolutionData.1 {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        }
        
        return cell
    }
    
    
}
