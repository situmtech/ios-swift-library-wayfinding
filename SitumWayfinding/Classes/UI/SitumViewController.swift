//
//  ViewControllerExtension.swift
//  SitumWayfinding
//
//  Created by Dimensiona on 2/1/23.
//
import Foundation

class SitumViewController: UIViewController {
    //TODO: For now it is limited to controllers inheriting from UIViewController. When the minimun version supported changes to iOS 13 simplify this class or even remove it. The goal should be to find a method to perform the managing of changes between light and dark mode in the same way in a UIViewController a UITableViewController...
    
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
