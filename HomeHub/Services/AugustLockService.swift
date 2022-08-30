import Foundation
import Alamofire
import Keys

protocol AugustLockServiceProtocol {
    var lockState: LockState? { get set }
    var healthy: Bool { get set }
    var delegate: AugustLockServiceDelegate? { get set }
    
    func toggleLockState(
        completion: @escaping () -> Void
    )
}

protocol AugustLockServiceDelegate: AnyObject {
    func augustLockServiceUpdateHealthStatus(
        _ augustLockService: AugustLockService
    )

    func augustLockService(
        _ augustLockService: AugustLockService,
        lockedStateUpdated lockState: LockState?
    )
}

enum LockState: String {
    case locked = "kAugLockState_Locked"
    case unlocked = "kAugLockState_Unlocked"
    
    var associatedImage: UIImage? {
        switch self {
        case .unlocked:
            return UIImage(named: "unlockedLock")
        case .locked:
            return UIImage(named: "lockedLock")
        }
    }
    
    var formattedString: String {
        switch self {
        case .unlocked:
            return "Unlocked"
        case .locked:
            return "Locked"
        }
    }
}

// https://nolanbrown.medium.com/august-lock-rest-apis-the-basics-7ec7f31e7874
class AugustLockService: AugustLockServiceProtocol, LoggerProtocol {
    // MARK: - Init

    init(delegate: AugustLockServiceDelegate? = nil) {
        self.delegate = delegate
//        pollLockState()
    }

    // MARK: - Private properties

    private let host = "https://api-production.august.com/remoteoperate"
    private var statusPath: String { "/\(lockId)/status" }
    private var lockPath: String { "/\(lockId)/lock" }
    private var unlockPath: String { "/\(lockId)/unlock" }
    
    private lazy var accessToken: String = {
        keys.augustAccessToken
    }()
    
    private lazy var lockId: String = {
        keys.augustLockId
    }()

    private var headers: HTTPHeaders {
        [
            "Content-Type": "application/json",
            "Accept-Version": "0.0.1",
            "x-august-api-key": "79fd0eb6-381d-4adf-95a0-47721289d1d9",
            "x-kease-api-key": "79fd0eb6-381d-4adf-95a0-47721289d1d9",
            "x-august-access-token": accessToken
        ]
    }
    
    private let keys = HomeHubKeys()

    // MARK: - Public properties

    var lockState: LockState? {
        didSet {
            if lockState != oldValue {
                log("Lock State changed: \(lockState?.formattedString ?? "nil")")
                delegate?.augustLockService(self, lockedStateUpdated: lockState)
            }
        }
    }

    var healthy: Bool = false {
        didSet {
            if healthy != oldValue {
                log("Health Status changed: \(healthy)")
                delegate?.augustLockServiceUpdateHealthStatus(self)
            }
        }
    }

    weak var delegate: AugustLockServiceDelegate?

    // MARK: - Public methods
    
    func toggleLockState(
        completion: @escaping () -> Void
    ) {
        guard lockState != nil else {
            completion()
            return
        }

        let path = lockState == .locked ? unlockPath : lockPath
        let url = host + path
        log("Calling endpoint \(path)")
        putAugust(url) { responseBody in
            let lockState = self.getLockStateFromBody(responseBody)
            self.lockState = lockState

            completion()
        }
    }
    
    // MARK: - Private methods

    private func pollLockState() {
        let url = host + statusPath
        putAugust(url) { responseBody in
            if let lockState = self.getLockStateFromBody(responseBody) {
                self.healthy = true
                self.lockState = lockState
            } else {
                self.healthy = false
                self.lockState = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: { [weak self] in
                self?.pollLockState()
            })
        }
    }

    private func deserializeAndFormatResponse(
        _ response: DefaultDataResponse
    ) -> [String: Any]? {
        guard let data = response.data else {
            return nil
        }

        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        return json as? [String: Any]
    }

    private func getLockStateFromBody(
        _ body: [String: Any]?
    ) -> LockState? {
        guard let status = body?["status"] as? String else {
            return nil
        }

        return LockState.init(rawValue: status)
    }
    
    private func putAugust(
        _ url: String,
        completion: @escaping ([String: Any]?) -> Void
    ) {
        Alamofire.request(
            url,
            method: .put,
            headers: headers).responseJSON { response in
            switch response.result {
            case let .success(value):
                let json = value as? [String: Any]
                completion(json)
            case let .failure(error):
                self.healthy = false
                self.logError(error)
                completion(nil)
            }
        }
    }
}
