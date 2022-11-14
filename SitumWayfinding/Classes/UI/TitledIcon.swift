import Foundation

extension UIImage {
    func setTitle(title: String, size: CGFloat, color: UIColor, weight: UIFont.Weight) -> UIImage {
        let subView = UIView()
        
        let font = UIFont(name: "Roboto-Black", size: size) ?? UIFont.systemFont(ofSize: 22)
        
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
        let sizeFrame = CGRect(
            x: 4.0,
            y: 4.0,
            width: 120.0,
            height: labelHeight(text: title, font: font, width: 120.0)
        )
   
        let titleLabel = StrokeLabel(frame: sizeFrame)
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.textAlignment = .center
        titleLabel.customfont = font
        titleLabel.textForegroundColor = color
        titleLabel.strockedText = title
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.numberOfLines = 0
       
        return titleLabel
    }
    
    private func labelHeight(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let sizeFrame = CGRect(
            x: 0.0,
            y: 0.0,
            width: width,
            height: CGFloat.greatestFiniteMagnitude
        )
        let label:UILabel = UILabel(frame: sizeFrame)
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = font
        label.text = text
        label.sizeToFit()
        return label.frame.height
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
