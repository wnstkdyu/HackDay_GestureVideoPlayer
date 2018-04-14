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
    case none
}

enum Resolution: String {
    case high = "720P"
    case normal = "480P"
    case low = "240P"
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
            }
        case false:
            let resolutionData = resolutionsArray[indexPath.row]
            cell.textLabel?.text = resolutionData.0.rawValue
            
            if resolutionData.1 {
                cell.accessoryType = .checkmark
            }
        }
        
        return cell
    }
    
    
}
