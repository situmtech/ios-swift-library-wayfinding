//
//  IconsStore.swift
//  SitumWayfinding
//
//  Created by fsvilas on 2/12/21.
//

import Foundation
import SitumSDK

class IconsStore {
    var poiCategoryIcons: Dictionary<String, UIImage> = [:]
    let iconScaleFactor = 50
    
    //TODO Refactor to Repository Factory and use await/async
    func obtainIconFor(category:SITPOICategory, completion: @escaping(UIImage?) -> Void) {
        if poiCategoryIcons[category.code] != nil {
            completion(poiCategoryIcons[category.code]!)
        } else {
            SITCommunicationManager.shared().fetchSelected(false, iconFor: category, withCompletion: { iconData, error in
                if error != nil {
                    Logger.logErrorMessage("error retrieving icon data")
                    completion(nil)
                } else {
                    DispatchQueue.main.async(execute: {
                        var iconImg: UIImage? = nil
                        if let uIconData = iconData {
                            iconImg = ImageUtils.scaleImageToSize(image: UIImage(data: uIconData)!, newSize: CGSize(width: CGFloat(self.iconScaleFactor), height: CGFloat(self.iconScaleFactor)))
                            
                        }
                        self.poiCategoryIcons[category.code] = iconImg
                        completion(iconImg)
                    })
                }
            })
        }
    }
}
