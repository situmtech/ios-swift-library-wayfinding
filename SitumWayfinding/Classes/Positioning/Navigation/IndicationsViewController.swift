//
// Created by Lapisoft on 21/3/22.
//

import Foundation
import UIKit

class IndicationsViewController: UIViewController {
    
    @IBOutlet weak var indicationView: UIView!
    @IBOutlet weak var destinationLabel: UILabel!
    @IBOutlet weak var indicationImage: UIImageView!
    @IBOutlet weak var indicationLoading: UIActivityIndicatorView!
    @IBOutlet weak var indicationLabel: UILabel!
    
    @IBOutlet weak var nextIndicationView: UIView!
    @IBOutlet weak var nextIndicationLabel: UILabel!
    @IBOutlet weak var nextIndicationImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        self.setupIndicationView()
        self.setupNextIndicationView()
        self.showLoading()
    }
    
    private func setupIndicationView() {
        self.indicationView.backgroundColor = .white
        self.indicationView.layer.borderWidth = 2
        self.indicationView.layer.borderColor = UIColor.primaryDiminished.cgColor
        self.indicationView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
        self.indicationView.shadow()
    
        self.destinationLabel.font = .small
        self.destinationLabel.textColor = .primary
        self.indicationLabel.font = .bigBold
        self.indicationLabel.textColor = .primary
        self.indicationLabel.numberOfLines = 0
        
        self.indicationImage.tintColor = .primary
        
        self.indicationLoading.tintColor = .primary
        if #available(iOS 13.0, *) {
            self.indicationLoading.style = .large
        }
        self.indicationLoading.startAnimating()
    }
    
    private func setupNextIndicationView() {
        self.nextIndicationView.backgroundColor = .primary
        self.nextIndicationView.roundCorners(corners: [.bottomLeft, .bottomRight])
        self.nextIndicationView.shadow()
        self.nextIndicationLabel.font = .small
        self.nextIndicationLabel.textColor = .white
    
        self.nextIndicationImage.image = UIImage(named: "situm_direction_destination",
            in: SitumMapsLibrary.bundle, compatibleWith: nil)
        self.nextIndicationImage.tintColor = .white
    }
    
    func setInstructions(progress: SITNavigationProgress, destination: String) {
        if progress.currentIndication.action == .sitCalculating {
            self.showLoading()
        } else {
            self.hideLoading()
            self.setDestination(destination: destination)
            self.indicationLabel.text = progress.currentIndication.humanReadableMessage()
            self.indicationImage.image = self.getIndicationImage(indication: progress.currentIndication)
            self.nextIndicationLabel.text = NSLocalizedString("navigation.nextInstruction",
                bundle: SitumMapsLibrary.bundle,comment: "")
            self.nextIndicationImage.image = self.getIndicationImage(indication: progress.nextIndication)
        }
    }
    
    func setDestination(destination: String) {
        self.destinationLabel.text = destination
    }
    
    private func showLoading() {
        self.indicationLoading.isHidden = false
        self.indicationImage.isHidden = true
        self.indicationView.roundCorners(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
        self.indicationLabel.text = NSLocalizedString("navigation.loadingRoute",
            bundle: SitumMapsLibrary.bundle, comment: "")
        
        self.nextIndicationView.isHidden = true
    }
    
    private func hideLoading() {
        self.indicationLoading.isHidden = true
        self.indicationImage.isHidden = false
        self.indicationView.roundCorners(corners: [.topLeft, .topRight, .bottomRight])
        
        self.nextIndicationView.isHidden = false
    }
    
    private func getIndicationImage(indication: SITIndication) -> UIImage? {
        switch indication.action {
        case .sitCalculating:
            return UIImage(named: "situm_direction_empty", in: SitumMapsLibrary.bundle, compatibleWith: nil)
        case .sitInvalidAction:
            return UIImage(named: "situm_direction_empty", in: SitumMapsLibrary.bundle, compatibleWith: nil)
        case .sitTurn:
            switch indication.orientation {
            case .sitInvalidOrientation:
                return UIImage(named: "situm_direction_empty", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            case .sitStraight:
                return UIImage(named: "situm_direction_continue", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            case .sitVeerRight, .sitRight, .sitSharpRight:
                return UIImage(named: "situm_direction_turn_right", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            case .sitVeerLeft, .sitLeft, .sitSharpLeft:
                return UIImage(named: "situm_direction_turn_left", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            case .sitBackward:
                return UIImage(named: "situm_direction_backward", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            @unknown default:
                return UIImage(named: "situm_direction_empty", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            }
        case .sitGoAhead:
            return UIImage(named: "situm_direction_continue", in: SitumMapsLibrary.bundle, compatibleWith: nil)
        case .sitChangeFloor:
            if indication.verticalDistance > 0 {
                return UIImage(named: "situm_direction_stairs_up", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            } else {
                return UIImage(named: "situm_direction_stairs_down", in: SitumMapsLibrary.bundle, compatibleWith: nil)
            }
        case .sitEnd:
            return UIImage(named: "situm_direction_destination", in: SitumMapsLibrary.bundle, compatibleWith: nil)
        @unknown default:
            return UIImage(named: "situm_direction_empty", in: SitumMapsLibrary.bundle, compatibleWith: nil)
        }
    }
}
