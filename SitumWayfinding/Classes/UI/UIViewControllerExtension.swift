//
//  ViewControllerExtension.swift
//  SitumWayfinding
//
//  Created by Dimensiona on 2/1/23.
//
import Foundation

extension UIViewController {
    
    func userInterfaceStyle() -> Dictionary<String, UIColor> {
        var tintColor: UIColor = .black
        var backgroundColor: UIColor = .white
        var colorText: UIColor = .black
        
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                tintColor = .white
                backgroundColor = .black
                colorText = .white
            }
        }
        
        return ["tintColor": tintColor, "backgroundColor": backgroundColor, "colorText": colorText]
    }
    
    func modeIcon(nameImage: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            let tintColor = self.userInterfaceStyle()["tintColor"]!
            
            switch(nameImage) {
                case "swf_info":
                    return UIImage(systemName: "info.circle")?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                case "situm_navigation_cancel":
                    let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .thin, scale: .large)
                    return UIImage(systemName: "multiply.circle", withConfiguration: largeConfig)?
                        .withTintColor(tintColor, renderingMode: .alwaysOriginal)
                case "situm_walk":
                    return UIImage(systemName: "figure.walk")?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                case "situm_clock_time":
                    return UIImage(systemName: "clock")?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
                default:
                    return nil
            }
        } else {
            return UIImage(
                named: nameImage,
                in: SitumMapsLibrary.bundle,
                compatibleWith: nil
            )
        }
    }
}
