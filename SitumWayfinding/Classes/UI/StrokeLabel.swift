//
//  StrokeLabel.swift
//  SitumWayfinding
//
//  Created by Bruno Gómez on 19/10/22.
//  Copyright © 2022 Situm Technologies. All rights reserved.
//

class StrokeLabel: UILabel {
    
    var textStrokeColor: UIColor = UIColor.white
    
    var textForegroundColor: UIColor = UIColor.gray
    
    var customfont: UIFont = UIFont.systemFont(ofSize: 22)
    
    var strockedText: String = "" {
        willSet(newValue) {
            let strokeTextAttributes : [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.strokeColor : textStrokeColor,
                NSAttributedString.Key.foregroundColor : textForegroundColor,
                NSAttributedString.Key.strokeWidth : -5.0,
                NSAttributedString.Key.font : customfont
            ] as [NSAttributedString.Key  : Any]
            
            let customizedText = NSMutableAttributedString(
                string: newValue,
                attributes: strokeTextAttributes
            )
            attributedText = customizedText
        }
    }
}

