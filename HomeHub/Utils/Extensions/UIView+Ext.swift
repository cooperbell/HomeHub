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
}
