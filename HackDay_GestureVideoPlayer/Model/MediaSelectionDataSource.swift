//
//  MediaSelectionDataSource.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 14..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

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
