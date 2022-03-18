import Foundation

class GeneralToastView: UIView, ToastView {
    private let minHeight: CGFloat
    private let minWidth: CGFloat
    
    private let darkBackground: UIColor
    private let lightBackground: UIColor
    
    private let child: UIView
    private var toast: Toast?
    
    init(
        child: UIView,
        minHeight: CGFloat = 60,
        minWidth: CGFloat = 150,
        darkBackground: UIColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1.00),
        lightBackground: UIColor = UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1.00)
    ) {
        self.minWidth = minWidth
        self.minHeight = minHeight
        self.darkBackground = darkBackground
        self.lightBackground = lightBackground
        self.child = child
        
        super.init(frame: .zero)
        
        addSubview(child)
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createView(for toast: Toast) {
        self.toast = toast
        
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight),
            widthAnchor.constraint(greaterThanOrEqualToConstant: minWidth),
            leadingAnchor.constraint(greaterThanOrEqualTo: superview.leadingAnchor, constant: 10),
            trailingAnchor.constraint(lessThanOrEqualTo: superview.trailingAnchor, constant: -10),
            bottomAnchor.constraint(equalTo: superview.layoutMarginsGuide.bottomAnchor, constant: 0),
            centerXAnchor.constraint(equalTo: superview.centerXAnchor)
        ])
        
        addSubviewConstraints()
        style()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        UIView.animate(withDuration: 0.5) {
            self.style()
        }
    }
    
    private func style() {
        layoutIfNeeded()
        clipsToBounds = true
        layer.cornerRadius = frame.height / 2
        
        if #available(iOS 12.0, *) {
            backgroundColor = traitCollection.userInterfaceStyle == .light ? lightBackground : darkBackground
        } else {
            backgroundColor = lightBackground
        }
        
        addShadow()
    }
    
    private func addSubviewConstraints() {
        child.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            child.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 25),
            child.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -25)
        ])
    }
    
    private func addShadow() {
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 8
    }
}