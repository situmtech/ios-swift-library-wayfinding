import Foundation

protocol ToastView: UIView {
    func createView(for toast: Any)
}
