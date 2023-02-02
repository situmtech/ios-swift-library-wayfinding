//
//  File.swift
//  SitumWayfinding
//
//  Created by fsvilas on 10/1/23.
//

import Foundation

extension UIButton {
    func configure(imageName: String?, buttonColors: ButtonColors, for state: UIControl.State){
        setIcon(imageName: imageName, for: state)
        self.adjustColors(buttonColors)
    }
    
    func setIcon(imageName: String?, for state: UIControl.State){
        if let imageName = imageName{
            let image = UIImage(named: imageName,
                                in: SitumMapsLibrary.bundle,
                                compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
            setImage(image, for: state)
        } else {
            setImage(nil, for: state)
        }
    }
    
    func adjustColors(_ buttonColors: ButtonColors) {
        self.tintColor = buttonColors.textColor
        self.backgroundColor = buttonColors.backgroundColor
    }
}

struct ButtonColors {
    let textColor : UIColor
    let backgroundColor : UIColor
    
    init(iconTintColor:UIColor, backgroundColor:UIColor) {
        self.textColor = iconTintColor
        self.backgroundColor = backgroundColor
    }
}
