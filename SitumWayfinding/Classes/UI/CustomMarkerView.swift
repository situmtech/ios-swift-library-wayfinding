import Foundation

class CustomMarkerView {
    private let subView = UIView()
    private let mainView = UIView()
    private let markerImgView = UIImageView()
    
    private var markerImage: UIImage
    private var padding: CGFloat = 8.0
    private var titleLabel: UILabel?
    private var displayFont = false
    
    init(markerImage: UIImage) {
        self.markerImage = markerImage
    }
    
    private func getLabel(font: UIFont, color: UIColor, title: String) -> UILabel {
        let sizeFrame = CGRect(x: 4.0, y: 4.0, width: 150.0, height: font.lineHeight)
        let titleLabel : UILabel = UILabel(frame: sizeFrame)
        
        let textFontAttributes: [NSAttributedString.Key : Any]  = [
            NSAttributedString.Key.font : font,
            NSAttributedString.Key.foregroundColor: color,
            NSAttributedString.Key.strokeColor: UIColor.white,
            NSAttributedString.Key.strokeWidth: -2
        ]
        
        let mutableString = NSMutableAttributedString(string: title, attributes: textFontAttributes)
        
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.attributedText = mutableString
        titleLabel.numberOfLines = 0
        titleLabel.sizeToFit()
        titleLabel.backgroundColor = UIColor.clear
        
        let noLines = titleLabel.frame.size.height / font.lineHeight

        if noLines > 2 {
            titleLabel.numberOfLines = 2
        }
        
        titleLabel.frame = CGRect(
            x: 4.0,
            y: 4.0,
            width: titleLabel.frame.width,
            height: (noLines > 2) ? 2 * font.lineHeight : 24.0
        )
        
        return titleLabel
    }
    
    func titlePoi(title: String, size: CGFloat, color: UIColor, weight: UIFont.Weight) {
        self.displayFont = true
        
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        
        let titleLabel = self.getLabel(font: font, color: color, title: title)
        
        self.subView.addSubview(titleLabel)
        self.subView.frame = CGRect(
            x: 0.0,
            y: 0.0,
            width: 2 * 4.0 + titleLabel.frame.width,
            height: 2 * 4.0 + titleLabel.frame.height
        )
        self.subView.backgroundColor = UIColor.clear
    }
    
    func getIcon() -> UIImage {
        markerImgView.frame = CGRect(
            x: subView.center.x - self.markerImage.size.width / 2,
            y: subView.frame.height,
            width: self.markerImage.size.width,
            height: self.markerImage.size.height
        )
        markerImgView.image = self.markerImage
        markerImgView.contentMode = .scaleAspectFit

        mainView.addSubview(markerImgView)

        mainView.frame = CGRect(
            x: 0.0,
            y: 0.0,
            width: subView.frame.width,
            height: subView.frame.height + 4.0 + markerImgView.frame.height
        )
        mainView.addSubview(subView)
        mainView.backgroundColor = UIColor.clear
        
        UIGraphicsBeginImageContextWithOptions(mainView.bounds.size, false, UIScreen.main.scale)
        
        if displayFont {
            mainView.layer.render(in: UIGraphicsGetCurrentContext()!)
            let icon : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
            return icon
        } else {
            return markerImage
        }
    }
}
