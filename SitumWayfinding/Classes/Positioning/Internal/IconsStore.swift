//
//  IconsStore.swift
//  SitumWayfinding
//
//  Created by fsvilas on 2/12/21.
//

import Foundation
import SitumSDK

class IconsStore {
    var poiCategoryIcons: Dictionary<String, [UIImage?]> = [:]
    let iconScaleFactor = 50
    
    //TODO Refactor to Repository Factory and use await/async
    func obtainIconFor(category:SITPOICategory, completion: @escaping([UIImage?]?) -> Void) {
        if poiCategoryIcons[category.code] != nil {
            completion(poiCategoryIcons[category.code]!)
        } else {
            DispatchQueue.main.async(execute: {
                self.obtainUnSelectedIcon(category: category) { items in
                    self.poiCategoryIcons[category.code] = items
                    completion(items)
                }
            })
        }
    }
    
    func scaledImage(data: Data) -> UIImage {
        return ImageUtils.scaleImageToSize(
            image: UIImage(data: data)!,
            newSize: CGSize(
                width: CGFloat(self.iconScaleFactor),
                height: CGFloat(self.iconScaleFactor))
        )
    }
    
    private func obtainUnSelectedIcon(category: SITPOICategory, completion: @escaping([UIImage?]?) -> Void) {
        SITCommunicationManager.shared().fetchSelected(false, iconFor: category, withCompletion: { iconData, error in
            if error != nil {
                Logger.logErrorMessage("error retrieving icon data")
                completion(nil)
            } else {
                DispatchQueue.main.async(execute: {
                    if let uIconData = iconData {
                        let iconImg = self.scaledImage(data: uIconData)
                        self.obtainSelectedIcon(category: category) { item in
                            if let icon = item {
                                completion([iconImg, icon])
                            }
                            completion(nil)
                        }
                    }
                    completion(nil)
                })
            }
        })
    }
    
    private func obtainSelectedIcon(category: SITPOICategory, completion: @escaping(UIImage?) -> Void) {
        SITCommunicationManager.shared().fetchSelected(true, iconFor: category, withCompletion: { iconData, error in
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
