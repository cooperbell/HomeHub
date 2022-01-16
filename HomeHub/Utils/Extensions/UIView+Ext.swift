import Foundation
import UIKit

extension UIView {
    func applyCornerRadius(_ value: CGFloat) {
        layer.cornerRadius = value
    }

    func applyMaxCornerRadius() {
        let cornerRadius = frame.height / 2
        applyCornerRadius(cornerRadius)
    }

    func applyShadow(
        color: UIColor = .systemGray4,
        offset: CGSize = .zero,
        radius: CGFloat = 3,
        opacity: Float = 0.5
    ) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
    }
}
