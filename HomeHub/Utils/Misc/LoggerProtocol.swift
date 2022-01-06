import Foundation

protocol LoggerProtocol {
    func logError(_ error: Error?)
    func log(_ msg: String)
}

extension LoggerProtocol {
    func logError(_ error: Error?) {
        let msg = "Error: \(error?.toString ?? "Unknown error occurred")"
        log(msg)
    }

    func log(_ msg: String) {
        let dateFormatter = ISO8601DateFormatter()
        let prefix = "[\(dateFormatter.string(from: Date()))]"
        let infix = " (\(String(describing: type(of: self)))) - "
        print(prefix + infix + msg)
    }
}
