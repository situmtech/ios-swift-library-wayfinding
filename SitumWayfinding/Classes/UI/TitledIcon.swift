import Foundation

extension UIImage {
    func setTitle(title: String, size: CGFloat, color: UIColor, weight: UIFont.Weight) -> UIImage {
        let subView = UIView()
        
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        
        let titleLabel = self.getLabel(font: font, color: color, title: title)
        
        subView.addSubview(titleLabel)
        subView.frame = CGRect(
            x: 0.0,
            y: 0.0,
            width: 2 * 4.0 + titleLabel.frame.width,
            height: 2 * 4.0 + titleLabel.frame.height
        )
        subView.backgroundColor = UIColor.clear
        
        return prepareIconPoi(subView: subView)
    }
    
    private func getLabel(font: UIFont, color: UIColor, title: String) -> UILabel {
        let sizeFrame = CGRect(x: 4.0, y: 4.0, width: 150.0, height: font.lineHeight)
        let titleLabel : UILabel = UILabel(frame: sizeFrame)
    
        let textFontAttributes: [NSAttributedString.Key : Any]  = [
            .font : font,
            .foregroundColor: color,
            .backgroundColor: UIColor.white
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
    
    private func prepareIconPoi(subView: UIView) -> UIImage {
        let markerImgView = UIImageView()
        let mainView = UIView()
        
        markerImgView.frame = CGRect(
            x: subView.center.x - self.size.width / 2,
            y: subView.frame.height,
            width: self.size.width,
            height: self.size.height
        )
        markerImgView.image = self
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
        
        mainView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let icon : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return icon
    }
}
