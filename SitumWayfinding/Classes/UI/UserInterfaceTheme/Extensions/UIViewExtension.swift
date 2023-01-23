//
//  UIImageExtension.swift
//  SitumWayfinding
//
//  Created by fsvilas on 17/1/23.
//

import Foundation

extension UIView {
    func setSitumShadow(colorTheme: UIColorsTheme){
        if (colorTheme.isButtonShadowEnabled){
            layer.shadowColor = UIColor.darkGray.cgColor
            layer.shadowOpacity = 0.8
            layer.shadowRadius = 8.0
            layer.shadowOffset = CGSize(width: 7.0, height: 7.0)
        } else {
            layer.shadowOpacity = 0.0
        }
    }
}
