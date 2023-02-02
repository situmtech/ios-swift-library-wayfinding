//
//  SitumView.swift
//  SitumWayfinding
//
//  Created by Adrián Rodríguez on 19/06/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import Foundation
import UIKit

/**
 This class extends UIView and provides a way to include the wayfinding view in your app.
 */
@IBDesignable
public class SitumView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        try! setupSitumView()
    }
    
    private func setupSitumView() throws {
        let credentials: Credentials = UserDefaultsWrapper.getCredentialsFromPlist()
        let buildingId: String = UserDefaultsWrapper.getActiveBuildingFromPlist()
        // Here we use an empty view controller since it's not gonna be used. The controller is only needed when loading the view programmatically.
        let library = SitumMapsLibrary(containedBy: self, controlledBy: UIViewController())
        library.setCredentials(credentials)
        
        var mode = "light"
        
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                mode = "dark"
            }
        }
        
        try library.loadFromView(buildingWithId: buildingId)
    }
}
