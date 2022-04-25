//
//  IconsStore.swift
//  SitumWayfinding
//
//  Created by fsvilas on 2/12/21.
//

import Foundation
import SitumSDK
import Combine


class IconsStore {
    var poiCategoryIcons: Dictionary<String, [UIImage?]> = [:]
    let iconScaleFactor = 50
    
    //TODO Refactor to Repository Factory and use await/async
    func obtainIconFor(category:SITPOICategory, completion: @escaping([UIImage?]?) -> Void) {
        if poiCategoryIcons[category.code] != nil {
            completion(poiCategoryIcons[category.code]!)
        } else {
            DispatchQueue.main.async(execute: {
                self.obtainIcon(category: category, selected: false) { iconUnselected in
                    self.obtainIcon(category: category, selected: true) { iconSelected in
                        completion([iconUnselected, iconSelected])
                    }
                }
            })
        }
    }
    
    private func scaledImage(data: Data) -> UIImage {
        return ImageUtils.scaleImageToSize(
            image: UIImage(data: data)!,
            newSize: CGSize(
                width: CGFloat(self.iconScaleFactor),
                height: CGFloat(self.iconScaleFactor))
        )
    }
    
    private func obtainIcon(category: SITPOICategory, selected: Bool, completion: @escaping(UIImage?) -> Void) {
        SITCommunicationManager.shared().fetchSelected(selected, iconFor: category, withCompletion: { iconData, error in
            if error != nil {
                Logger.logErrorMessage("error retrieving icon data")
                completion(nil)
            } else {
                DispatchQueue.main.async(execute: {
                    if let uIconData = iconData {
                        let iconImg = self.scaledImage(data: uIconData)
                        completion(iconImg)
                    }
                    completion(nil)
                })
            }
        })
    }
}
