//
//  ImageUtils.swift
//  SitumMappingTool
//
//  Created by Cristina Sánchez Barreiro on 11/04/2019.
//  Copyright © 2019 Situm Technologies S.L. All rights reserved.
//

import Foundation
import UIKit

class ImageUtils {
    class func scaleImageToSize(image: UIImage, newSize: CGSize) -> UIImage {
        if __CGSizeEqualToSize(image.size, newSize) {
            return image;
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    

    class func scaleImage(image: UIImage) -> UIImage {
        let height = Float(image.size.height)
        let width = Float(image.size.width)
        
        let maxSize = ImageUtils.maxSizeForDevice()
        
        let heightFactor = height / maxSize
        let widthFactor = width / maxSize
        
        if heightFactor <= 1 && widthFactor <= 1 {
            return image
        }
        
        let scale = heightFactor >= widthFactor ? heightFactor : widthFactor;
        let newSize = CGSize(width: CGFloat(width / scale), height: CGFloat(height / scale))
        return ImageUtils.scaleImageToSize(image: image, newSize: newSize)
    }

    class func maxSizeForDevice() -> Float {
        if UIScreen.main.scale == 2.0 {
            return 2000
        }
        return 1350
    }
}
