//
//  NavigationController.swift
//  HackDay_GestureVideoPlayer
//
//  Created by Alpaca on 2018. 4. 6..
//  Copyright © 2018년 Alpaca. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    
    override var shouldAutorotate: Bool {
        guard let topViewController = topViewController else { return false }
        
        return topViewController.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        guard let topViewController = topViewController else { return [.portrait] }
        
        return topViewController.supportedInterfaceOrientations
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
