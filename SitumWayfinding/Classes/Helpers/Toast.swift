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
    
    func text(
        title: String,
        subtitle: String,
        config: ToastConfiguration = ToastConfiguration()
    ) -> Toast {
        let view = GeneralToastView(child: TextToastView(title: title, subtitle: subtitle))
        return self.init(view: view, config: config)
    }
    
    func show(type: UINotificationFeedbackGenerator.FeedbackType, time: TimeInterval = 0) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
        show(after: time)
    }
    
    func show(after delay: TimeInterval = 0) {
        config.view?.addSubview(view) ?? topController()?.view.addSubview(view)
        view.createView(for: self)
        
        UIView.animate(withDuration: config.animationTime, delay: delay, options: [.curveEaseOut, .allowUserInteraction]) {
            self.view.transform = .identity
        } completion: { [self] _ in
            if config.autoHide {
                close(after: config.displayTime)
            }
        }
    }
    
    @objc func close(after time: TimeInterval = 0, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: config.animationTime, delay: time, options: [.curveEaseIn, .allowUserInteraction], animations: {
            self.view.transform = self.initialTransform
        }, completion: { _ in
            self.view.removeFromSuperview()
            completion?()
        })
    }
    
    private func topController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        
        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return nil
    }
}
