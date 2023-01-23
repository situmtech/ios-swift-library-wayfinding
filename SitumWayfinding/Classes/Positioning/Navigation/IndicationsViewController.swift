//
// Created by Lapisoft on 21/3/22.
//

import Foundation
import UIKit

class IndicationsViewController: SitumViewController {
    
    @IBOutlet weak var indicationView: UIView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var indicationImage: UIImageView!
    @IBOutlet weak var indicationLoading: UIActivityIndicatorView!
    @IBOutlet weak var indicationLabel: UILabel!
    
    @IBOutlet weak var nextIndicationView: UIView!
    @IBOutlet weak var nextIndicationLabel: UILabel!
    @IBOutlet weak var nextIndicationImage: UIImageView!
    
    let indicationViewCornerRadius = RoundCornerRadius.normal 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.setupIndicationView()
        self.setupNextIndicationView()
        self.showNavigationLoading()
    }
    
    private func setupIndicationView() {
        self.indicationView.layer.borderWidth = 2
        self.indicationView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: indicationViewCornerRadius)
        self.indicationView.shadow()
    
        self.destinationLabel.font = .small
        self.destinationLabel.textColor = uiColorsTheme.primaryColor
        self.indicationLabel.font = .bigBold
        self.indicationLabel.textColor = uiColorsTheme.primaryColor
        self.indicationLabel.numberOfLines = 0
        self.indicationLoading.startAnimating()
    }
    
    
    
    private func setupNextIndicationView() {
        self.nextIndicationView.roundCorners(corners: [.bottomLeft, .bottomRight], radius: indicationViewCornerRadius)
        self.nextIndicationView.shadow()
        self.nextIndicationLabel.font = .small
        self.nextIndicationLabel.textColor = uiColorsTheme.backgroundedButtonsIconstTintColor
        self.nextIndicationImage.image = UIImage(named: "situm_direction_destination",
            in: SitumMapsLibrary.bundle, compatibleWith: nil)
        self.nextIndicationImage.tintColor = uiColorsTheme.backgroundedButtonsIconstTintColor
    }
    
    func setupIndicationViewsColors(){
        self.indicationView.layer.borderColor = uiColorsTheme.primaryColorDimished.cgColor
        self.indicationView.backgroundColor =  uiColorsTheme.backgroundColor
        self.indicationImage.tintColor =  uiColorsTheme.iconsTintColor
        self.indicationLoading.tintColor =  uiColorsTheme.iconsTintColor
        self.indicationLabel.textColor = uiColorsTheme.textColor
        self.destinationLabel.textColor = uiColorsTheme.textColor
        self.nextIndicationView.backgroundColor = uiColorsTheme.primaryColor
    }
    
    
    func setInstructions(progress: SITNavigationProgress, destination: String) {
        if progress.currentIndication.action == .sitCalculating {
            showNavigationLoading()
            indicationLabel.text = progress.currentIndication.humanReadableMessage()
        } else {
            hideLoading()
            setDestination(destination: destination)
            indicationLabel.text = progress.currentIndication.humanReadableMessage()
            let currentIndicationImageName = getIndicationsImageName(indication:progress.currentIndication)
            indicationImage.setSitumImage(name: currentIndicationImageName, tintColor: uiColorsTheme.iconsTintColor)
            nextIndicationLabel.text = NSLocalizedString("navigation.nextInstruction",
                bundle: SitumMapsLibrary.bundle,comment: "")
            nextIndicationLabel.textColor = uiColorsTheme.backgroundedButtonsIconstTintColor
            let nextIndicationImageName = getIndicationsImageName(indication:progress.nextIndication)
            nextIndicationImage.setSitumImage(name: nextIndicationImageName, tintColor: uiColorsTheme.backgroundedButtonsIconstTintColor)
        }
    }
    
    func setDestination(destination: String) {
        self.destinationLabel.text = destination
    }
        
    func showNavigationLoading() {
        self.indicationLoading.isHidden = false
        self.indicationImage.isHidden = true
        self.indicationView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight], radius: indicationViewCornerRadius)
        self.indicationLabel.text = NSLocalizedString("navigation.loadingRoute",
            bundle: SitumMapsLibrary.bundle, comment: "")
        
        self.nextIndicationView.isHidden = true
    }
    
    private func hideLoading() {
        self.indicationLoading.isHidden = true
        self.indicationImage.isHidden = false
        var corners: UIRectCorner
        if UIApplication.shared.userInterfaceLayoutDirection == .leftToRight {
            corners = [.topLeft, .topRight, .bottomRight]
        } else {
            corners = [.topLeft, .topRight, .bottomLeft]
        }
        self.indicationView.roundCorners(corners: corners, radius: indicationViewCornerRadius)
        
        self.nextIndicationView.isHidden = false
    }
    
    private func getIndicationsImageName(indication: SITIndication)->String{
        switch indication.action {
        case .sitCalculating:
            return  "situm_direction_empty"
        case .sitInvalidAction:
            return  "situm_direction_empty"
        case .sitTurn:
            switch indication.orientation {
            case .sitInvalidOrientation:
                 return "situm_direction_empty"
            case .sitStraight:
                return "situm_direction_continue"
            case .sitVeerRight, .sitRight, .sitSharpRight:
                return "situm_direction_turn_right"
            case .sitVeerLeft, .sitLeft, .sitSharpLeft:
                return "situm_direction_turn_left"
            case .sitBackward:
                return  "situm_direction_backward"
            @unknown default:
                return "situm_direction_empty"
            }
        case .sitGoAhead:
            return  "situm_direction_continue"
        case .sitChangeFloor:
            if indication.verticalDistance > 0 {
                return  "situm_direction_stairs_up"
            } else {
                 return "situm_direction_stairs_down"
            }
        case .sitEnd:
            return  "situm_direction_destination"
        @unknown default:
            return  "situm_direction_empty"
        }
    }
}

extension IndicationsViewController {
    func isBeingPresented(){
        setupIndicationViewsColors()
        showNavigationLoading()
    }
    
    override func reloadScreenColors(){
        setupIndicationViewsColors()
    }
}
