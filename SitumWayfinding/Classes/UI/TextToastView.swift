import Foundation

class TextToastView: UIStackView {
    init(title: String, subtitle: String?) {
        super.init(frame: CGRect.zero)
        
        axis = .vertical
        alignment = .center
        distribution = .fillEqually
        
        if title != "" {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .systemFont(ofSize: 14, weight: .bold)
            titleLabel.numberOfLines = 1
            addArrangedSubview(titleLabel)
        }
        
        if let textSubtitle = subtitle {
            let subtitleLabel = UILabel()
            subtitleLabel.text = textSubtitle
            subtitleLabel.font = .systemFont(ofSize: 14, weight: .regular)
            subtitleLabel.numberOfLines = 3
            subtitleLabel.textColor = UIColor.black
            addArrangedSubview(subtitleLabel)
        }
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
