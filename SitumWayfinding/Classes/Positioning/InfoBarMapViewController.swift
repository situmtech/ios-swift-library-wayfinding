//
//  InfoBarMapViewController.swift
//  SitumWayfinding
//
//  Created by Lapisoft on 16/3/22.
//

import Foundation
import UIKit

class InfoBarMapViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var secondaryLabel: UILabel!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var topSeparator: UIView!
    
    private var centerConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        topSeparator.backgroundColor = .primaryDiminished
        
        let bundle = Bundle(for: type(of: self))
        prepareElements()
    }
    
    func setLogo(image: UIImage?) {
        logoImage.image = image
    }
    
    func setLabels(primary: String, secondary: String = "") {
        mainLabel.text = primary
        secondaryLabel.text = secondary
        centerPrimaryVerticallyIfNeeded(secondary: secondary)
    }
    
    private func centerPrimaryVerticallyIfNeeded(secondary: String) {
        if secondary == "" {
            if let constraint = centerConstraint {
                constraint.isActive = true
            } else {
                centerConstraint = mainLabel.layoutMarginsGuide.centerYAnchor.constraint(
                    equalTo: self.view.centerYAnchor)
                self.view.addConstraint(centerConstraint!)
            }
        } else {
            if let constraint = centerConstraint {
                constraint.isActive = false
            }
        }
    }
    
}

extension InfoBarMapViewController {
    func prepareElements() {
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                self.prepareLightOrDarkMode(tintColor: .white)
            } else {
                self.prepareLightOrDarkMode(tintColor: .black)
            }
        } else {
            imageView.image = UIImage(
                named: "swf_info",
                in: SitumMapsLibrary.bundle,
                compatibleWith: nil
            )
        }
    }
    
    @available(iOS 13.0, *)
    func prepareLightOrDarkMode(tintColor: UIColor) {
        imageView.image = UIImage(systemName: "info.circle")?.withTintColor(tintColor, renderingMode: .alwaysOriginal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        prepareElements()
    }
}
