//
//  ImageProvider.swift
//  SitumWayfinding
//
//  Created by fsvilas on 10/1/23.
//

import Foundation

extension UIImageView {
    func setSitumImage(name: String, tintColor: UIColor) {
        image = UIImage(
            named: name,
            in: SitumMapsLibrary.bundle,
            compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        self.tintColor = tintColor
    }
}
