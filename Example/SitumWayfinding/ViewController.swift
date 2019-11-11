//
//  ViewController.swift
//  ios-app-wayfindingExample
//
//  Created by Adrián Rodríguez on 16/05/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import UIKit
import SitumWayfinding
import SitumSDK

class ViewController: UIViewController {
   
    @IBOutlet var loadButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func onPressLoadButton(_ sender: Any) {
        self.performSegue(withIdentifier: "loadWayfindingSegue", sender: self)
    }
}

