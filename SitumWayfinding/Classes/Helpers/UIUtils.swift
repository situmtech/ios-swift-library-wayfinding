//
//  UIUtils.swift
//  ios-situm-module-poc
//
//  Created by Adrián Rodríguez on 23/05/2019.
//  Copyright © 2019 Situm Technologies. All rights reserved.
//

import UIKit

class UIUtils: NSObject {
    
    func viewControllerFromStoryboard(with vcID:String) -> UIViewController{
        let frameworkBundle = Bundle(identifier: "situm.SitumWayfinding")
        let storyboard = UIStoryboard(name: "SitumWayfinding", bundle: frameworkBundle)
        let viewController = storyboard.instantiateViewController(withIdentifier: vcID)
        return viewController
    }
    
    func present(the viewController:UIViewController, over parentViewController:UIViewController, in view:UIView){
        parentViewController.addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.bindFrameToSuperviewBounds()        
        viewController.didMove(toParent: parentViewController)
    }
    
    func presentFromView(the viewController:UIViewController, in view:UIView){
        view.addSubview(viewController.view)
        viewController.view.bindFrameToSuperviewBounds()
    }
}

// This allows to bind any view to the same size of its superview.
// https://stackoverflow.com/questions/18756640/width-and-height-equal-to-its-superview-using-autolayout-programmatically
extension UIView {
    
    /// helper method to adjust module view to supporting view
    func bindFrameToSuperviewBounds() {
        guard let superview = self.superview else {
            print("Error! `superview` was nil – call `addSubview(view: UIView)` before calling `bindFrameToSuperviewBounds()` to fix this.")
            return
        }
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: superview.topAnchor, constant: 0).isActive = true
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: 0).isActive = true
        self.leadingAnchor.constraint(equalTo: superview.leadingAnchor, constant: 0).isActive = true
        self.trailingAnchor.constraint(equalTo: superview.trailingAnchor, constant: 0).isActive = true
    }
    
    func roundCorners(corners: UIRectCorner) {
        let radius: CGFloat = 5
        if #available(iOS 11.0, *) {
            self.layer.maskedCorners = rectCornerToMaskedCorners(corners: corners)
            self.layer.cornerRadius = radius
        } else {
            let path = UIBezierPath(roundedRect: self.bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
        }
    }
    
    private func rectCornerToMaskedCorners(corners: UIRectCorner) -> CACornerMask {
        var maskedCorners: CACornerMask = []
        if corners.contains(.topLeft) {
            maskedCorners.insert(.layerMinXMinYCorner)
        }
        if corners.contains(.topRight) {
            maskedCorners.insert(.layerMaxXMinYCorner)
        }
        if corners.contains(.bottomLeft) {
            maskedCorners.insert(.layerMinXMaxYCorner)
        }
        if corners.contains(.bottomRight) {
            maskedCorners.insert(.layerMaxXMaxYCorner)
        }
        return maskedCorners
    }
    
    func shadow() {
        self.layer.shadowOffset = .zero
        self.layer.shadowRadius = 3
        self.layer.shadowOpacity = 0.4
    }
}
