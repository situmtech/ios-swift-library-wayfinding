//
// Created by Lapisoft on 16/3/22.
//

import Foundation
import UIKit

class InfoBarNavigationViewController: UIViewController {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var distanceRemainingImage: UIImageView!
    @IBOutlet weak var distanceRemainingLabel: UILabel!
    @IBOutlet weak var estimatedTimeLabel: UILabel!
    @IBOutlet weak var estimatedTimeImage: UIImageView!
    @IBOutlet weak var separatorLabel: UILabel!
    @IBOutlet weak var topSeparator: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        prepareElements()
        setLoadingState()
    }
    
    func updateProgress(progress: SITNavigationProgress) {
        if progress.currentIndication.action == .sitCalculating {
            self.setLoadingState()
            self.timeRemainingLabel.text = progress.currentIndication.humanReadableMessage()
        } else {
            self.timeRemainingLabel.text = self.formatTime(time: progress.improvedTimeToGoal)
            self.distanceRemainingLabel.text = self.formatDistance(distance: progress.distanceToGoal)
            self.estimatedTimeLabel.text = self.calculateEstimatedTime(timeToGoal: progress.improvedTimeToGoal)
        }
    }
    
    func setLoadingState() {
        timeRemainingLabel.text = NSLocalizedString("navigation.loadingRoute",
            bundle: SitumMapsLibrary.bundle, comment: "")
        distanceRemainingLabel.text = "-"
        estimatedTimeLabel.text = "-"
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        if let parent = self.parent as? PositioningViewController {
            parent.stopNavigationByUser()
        } else {
            Logger.logErrorMessage("Cancel of navigation should notify parent of type 'PositioningViewController' but the parent controller is not 'PositioningViewController'")
        }
    }
    
    func setLogo(image: UIImage?) {
        logoImage.image = image
    }
    
    private func formatTime(time: Float) -> String {
        let time = secondsToHoursMinutesSeconds(time)
        if time.hours > 0 {
            let format = NSLocalizedString("navigation.remainingHours", bundle: SitumMapsLibrary.bundle,
                comment: "Remaining time in hours")
            return String.localizedStringWithFormat(format, time.hours)
        } else if time.minutes > 0 {
            let format = NSLocalizedString("navigation.remainingMinutes", bundle: SitumMapsLibrary.bundle,
                comment: "Remaining time in minutes")
            return String.localizedStringWithFormat(format, time.minutes)
        } else {
            let format = NSLocalizedString("navigation.lessThanMinutes", bundle: SitumMapsLibrary.bundle,
                comment: "Less than x minutes")
            return String.localizedStringWithFormat(format, 1)
        }
    }
    
    private func formatDistance(distance: Float) -> String {
        return String.localizedStringWithFormat("%.1fm", distance)
    }
    
    private func secondsToHoursMinutesSeconds(_ seconds: Float) -> Time {
        let intSeconds = Int(seconds)
        return Time(hours: intSeconds / 3600, minutes: (intSeconds % 3600) / 60, seconds: (intSeconds % 3600) % 60)
    }
    
    private struct Time {
        var hours: Int
        var minutes: Int
        var seconds: Int
    }
    
    private func calculateEstimatedTime(timeToGoal: Float) -> String {
        let goalTime: Date = Date().addingTimeInterval(TimeInterval(timeToGoal))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: goalTime)
    }
}

//TODO: This has to be deleted when this change is added to the sdk
extension SITNavigationProgress {
    var improvedTimeToGoal: Float {
        get {
            return timeToGoal/1.4
        }
    }
}

extension InfoBarNavigationViewController {
    func prepareElements() {
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                self.prepareLightOrDarkMode(tintColor: UIColor.black, colorText: UIColor.black)
            } else {
                self.prepareLightOrDarkMode(tintColor: UIColor.white, colorText: UIColor.white)
            }
        } else {
            let cancelImage = UIImage(
                named: "situm_navigation_cancel",
                in: SitumMapsLibrary.bundle, compatibleWith: nil
            )
            
            self.distanceRemainingImage.image = UIImage(
                named: "situm_walk",
                in: SitumMapsLibrary.bundle,
                compatibleWith: nil
            )
            self.estimatedTimeImage.image = UIImage(
                named: "situm_clock_time",
                in: SitumMapsLibrary.bundle,
                compatibleWith: nil
            )
            
            self.cancelButton.setImage(cancelImage, for: .normal)
            self.cancelButton.tintColor = .primary
            self.timeRemainingLabel.textColor = .primary
            self.distanceRemainingLabel.textColor = .primary
            self.estimatedTimeLabel.textColor = .primary
            self.separatorLabel.textColor = .primary
        }
        
        self.timeRemainingLabel.font = .normalBold
        self.distanceRemainingLabel.font = .small
        self.estimatedTimeLabel.font = .small
        self.separatorLabel.font = .normal
        self.topSeparator.backgroundColor = .primaryDiminished
        
        
    }
    
    @available(iOS 13.0, *)
    func prepareLightOrDarkMode(tintColor: UIColor, colorText: UIColor) {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .thin, scale: .large)
        let cancelImage = UIImage(systemName: "multiply.circle", withConfiguration: largeConfig)
        self.distanceRemainingImage.image = UIImage(systemName: "figure.walk")
        self.estimatedTimeImage.image = UIImage(systemName: "clock")
        
        cancelImage?.withTintColor(tintColor)
        self.distanceRemainingImage.tintColor = tintColor
        self.estimatedTimeImage.tintColor = tintColor
        self.cancelButton.tintColor = tintColor
        self.timeRemainingLabel.textColor = colorText
        self.distanceRemainingLabel.textColor = colorText
        self.estimatedTimeLabel.textColor = colorText
        self.separatorLabel.textColor = colorText
        self.cancelButton.setImage(cancelImage, for: .normal)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        prepareElements()
    }
}
