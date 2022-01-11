import Foundation

extension Error {
    var toString: String {
        "\(self)"
    }
}

extension Array where Element == Error {
    var aggregated: String {
        map { $0.toString }
        .joined(separator: ", ")
    }
}
