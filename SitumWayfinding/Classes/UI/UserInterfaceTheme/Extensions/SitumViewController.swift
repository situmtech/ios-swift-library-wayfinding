//
//  ViewControllerExtension.swift
//  SitumWayfinding
//
//  Created by Dimensiona on 2/1/23.
//
import Foundation

class SitumViewController: UIViewController {
    var uiColorsTheme = UIColorsTheme()
    
    override func viewDidLoad() {
        configureUIColorsTheme()
        super.viewDidLoad()
    }
        
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) { // Resolve dynamic colors again
                configureUIColorsTheme()
                reloadScreenColors()
            }
        } else {
            configureUIColorsTheme()
            reloadScreenColors()
        }
    }
    
    func configureUIColorsTheme(){
        if #available(iOS 12.0, *) {
            uiColorsTheme = UIColorsTheme(userInterfaceStyle: traitCollection.userInterfaceStyle)
        }else{
            uiColorsTheme = UIColorsTheme()
        }
    }
    
    @objc dynamic func reloadScreenColors(){
        //Override this method to adecuate colors in your screen
    }
}
