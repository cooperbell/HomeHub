import Foundation
import SwiftyHue
import Keys

enum PhillipsHueServiceError: Error {
    case updateLightError(String?)
}

class PhillipsHueWrapper: LoggerProtocol {
    // MARK: - Init

    init() {
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
    }

    // MARK: - Private properties

    private let swiftyHue = SwiftyHue()

    private lazy var sendAPI = swiftyHue.bridgeSendAPI

    private lazy var resourceAPI = swiftyHue.resourceAPI

    private lazy var bridgeAccessConfig = {
        BridgeAccessConfig(
            bridgeId: keys.hueBridgeId,
            ipAddress: keys.hueIP,
            username: keys.hueUsername)
    }()
    
    private let keys = HomeHubKeys()

    func updateLight(
        id: String,
        value: Float,
        completion: @escaping (Error?) -> Void
    ) {
        var lightState = LightState()
        lightState.on = value > 0.0
        lightState.brightness = Int(value)

        sendAPI.updateLightStateForId(id, withLightState: lightState) { errors in
            if let errors = errors {
                let err = PhillipsHueServiceError.updateLightError(errors.aggregated)
                self.logError(err)
                completion(err)
            } else {
                completion(nil)
            }
        }
    }
    
    func fetchLights(
        completion: @escaping ([String: Light]?, Error?) -> Void
    ) {
        resourceAPI.fetchLights { result in
            switch result {
            case let .success(lights):
                completion(lights, nil)
            case let .failure(error):
                self.logError(error)
                completion(nil, error)
            }
        }
    }
}
