import Foundation

struct ToastConfiguration {
    let autoHide: Bool
    let displayTime: TimeInterval
    let animationTime: TimeInterval
    
    let view: UIView?
    
    /**
     - autoHide: When set to true, the toast will automatically close itself after display time has elapsed
     - displayTime: The duration the toast will be displayed before it will close when autoHide set to true.
     - animationTime: Duration of the animation
     - view: The view on which the toast view will be attached
     */
    
    init(
        autoHide: Bool = true,
        displayTime: TimeInterval = 1.7,
        animationTime: TimeInterval = 0.2,
        view: UIView? = nil
    ) {
        self.autoHide = autoHide
        self.displayTime = displayTime
        self.animationTime = animationTime
        self.view = view
    }
}
