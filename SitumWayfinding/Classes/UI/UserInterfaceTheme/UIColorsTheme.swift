//
//  File.swift
//  SitumWayfinding
//
//  Created by fsvilas on 9/1/23.
//

import Foundation
import UIKit

struct UIColorsTheme {
    //In future try to use UI Element Colors and Custom Dynamic colors. See WWDC19 Implementing dark mode on ios. iOS 13+
    
    //Constants, in future get from dashboard
    //Predefined color https://developer.apple.com/design/human-interface-guidelines/foundations/color
    private let clearModeBackgroundColor = UIColor(hex: "#FCFCFCFF")!
    private let darkModeBackgroundColor = UIColor(hex: "#262626FF")!
    private let clearModeTextColor = UIColor(hex: "#2C2C2EFF")!
    private let darkModeTextColor = UIColor(hex: "#F2F2F7FF")!
    //private let clearModeSecondaryTextColor = UIColor(hex: "#6B7280FF")!
    //private let darkModeSecondaryTextColor = UIColor(hex: "#6B7280FF")!
    private let clearModeIconsTintColor = UIColor(hex: "#2C2C2EFF")!
    private let darkModeIconsTintColor = UIColor(hex: "#F2F2F7FF")!
    private let allModesBackgroundedButtonsIconstTintColor = UIColor(hex: "#F2F2F7FF")!
    private let defaultPrimaryColor: UIColor = UIColor(hex: "#283380FF")!
    private let defaultDangerColor: UIColor = UIColor(hex: "#B00020FF")!
    
    
    //Organization theme information
    static var useDashboardTheme = false
    static var organizationTheme : SITOrganizationTheme?
    
    //Colors and UI configuration properties
    private(set) var isButtonShadowEnabled = false
    private(set) var iconsTintColor: UIColor!
    private(set) var backgroundColor: UIColor!
    private(set) var textColor: UIColor!
    private(set) var secondaryTextColor: UIColor!
    private(set) var backgroundedButtonsIconstTintColor: UIColor!
    var primaryColor: UIColor {
        var color = defaultPrimaryColor
        if UIColorsTheme.useDashboardTheme == true {
            if let organizationTheme = UIColorsTheme.organizationTheme { // Check if string is a valid string
                let generalColor = UIColor(hex:  organizationTheme.themeColors.primary ) ?? UIColor.gray
                color = organizationTheme.themeColors.primary.isEmpty ? defaultPrimaryColor : generalColor
            }
        }
        return color
    }
    var primaryColorDimished:UIColor {
        primaryColor.withAlphaComponent(0.5)
    }
    var dangerColor: UIColor {
        var color = defaultDangerColor
        if UIColorsTheme.useDashboardTheme == true {
            if let organizationTheme = UIColorsTheme.organizationTheme {
                let generalColor = UIColor(hex:  organizationTheme.themeColors.danger ) ?? UIColor.gray
                color = organizationTheme.themeColors.danger.isEmpty ? defaultDangerColor : generalColor
            }
        }
        return color
    }
    
    init() {
        configureLightMode()
    }
    
    @available(iOS 12.0, *)
    init(userInterfaceStyle: UIUserInterfaceStyle) {
        if userInterfaceStyle == .dark {
            configureDarkMode()
        }else{
            configureLightMode()
        }
    }
    
    mutating func configureLightMode() {
        iconsTintColor = clearModeIconsTintColor
        backgroundColor = clearModeBackgroundColor
        textColor = clearModeTextColor
        //secondaryTextColor = clearModeSecondaryTextColor
        backgroundedButtonsIconstTintColor = allModesBackgroundedButtonsIconstTintColor
        isButtonShadowEnabled = true
    }
    
    mutating func configureDarkMode() {
        iconsTintColor = darkModeIconsTintColor
        backgroundColor = darkModeBackgroundColor
        textColor = darkModeTextColor
        //secondaryTextColor = darkModeSecondaryTextColor
        backgroundedButtonsIconstTintColor = allModesBackgroundedButtonsIconstTintColor
        isButtonShadowEnabled = false
    }
    
}
