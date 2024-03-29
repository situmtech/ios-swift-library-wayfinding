//
// Created by Lapisoft on 16/3/22.
//

import Foundation
import UIKit

class InfoBarNavigationViewController: SitumViewController {
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
        customizeUI()
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
    func customizeUI() {
        customizeUIImagesAndColors()
        customizeUIFont()
    }
    
    func customizeUIImagesAndColors() {
        self.timeRemainingLabel.textColor = uiColorsTheme.textColor
        self.distanceRemainingLabel.textColor = uiColorsTheme.textColor
        self.estimatedTimeLabel.textColor = uiColorsTheme.textColor
        self.separatorLabel.textColor = uiColorsTheme.textColor
        self.distanceRemainingImage.setSitumImage(name: "situm_walk", tintColor: uiColorsTheme.iconsTintColor)
        self.estimatedTimeImage.setSitumImage(name: "situm_clock_time", tintColor: uiColorsTheme.iconsTintColor)
        let buttonsColors = ButtonColors(iconTintColor: uiColorsTheme.primaryColor, backgroundColor:.clear)
        self.cancelButton.configure(imageName: "situm_navigation_cancel", buttonColors:buttonsColors ,for: .normal)
        self.topSeparator.backgroundColor = uiColorsTheme.primaryColorDimished
    }
    
    func customizeUIFont() {
        self.timeRemainingLabel.font = .normalBold
        self.distanceRemainingLabel.font = .small
        self.estimatedTimeLabel.font = .small
        self.separatorLabel.font = .normal
    }
    
}


extension InfoBarNavigationViewController {
    func isBeingPresented(){
        customizeUIImagesAndColors()
    }
    
    override func reloadScreenColors(){
        customizeUIImagesAndColors()
    }
}
