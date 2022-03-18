import Foundation

class Toast {
    let view: ToastView
    private let config: ToastConfiguration
    
    private var initialTransform: CGAffineTransform {
        return CGAffineTransform(scaleX: 0.9, y: 0.9).translatedBy(x: 0, y: -100)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(view: ToastView, config: ToastConfiguration) {
        self.config = config
        self.view = view
        
        view.transform = initialTransform
    }
    
  
}
