import Foundation
import SwiftyHue
import Keys

protocol HueServiceProtocol {
    typealias LightData = [LightType: Light?]

    var healthy: Bool { get set }
    var delegate: HueServiceDelegate? { get set }
    
    func updateLight(_ light: LightType, value: Float)
}

protocol HueServiceDelegate: AnyObject {
    func hueService(
        _ hueService: HueService,
        updateHealthStatus healthy: Bool
    )
    
    func hueService(
        _ hueService: HueService,
        lightsUpdated lightData: [LightType: Int?]
    )
}

enum LightType {
    case foyer
    case livingRoom
    case office
    
    var toString: String {
        switch self {
        case .foyer:
            return "Foyer"
        case .livingRoom:
            return "Living Room"
        case .office:
            return "Office"
        }
    }

    var hueID: String {
        switch self {
        case .foyer:
            return "4"
        case .livingRoom:
            return "5"
        case .office:
            return "3"
        }
    }
}

class HueService: HueServiceProtocol, LoggerProtocol {
    // MARK: - Init

    init(delegate: HueServiceDelegate? = nil) {
        self.delegate = delegate
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
        pollLights()
    }

    // MARK: - Private properties

    private let swiftyHue = SwiftyHue()

    private lazy var sendAPI = swiftyHue.bridgeSendAPI

    private lazy var resourceAPI = swiftyHue.resourceAPI
    
    private var lights: LightData = [
        .foyer: nil,
        .livingRoom: nil,
        .office: nil
    ]

    private lazy var bridgeAccessConfig = {
        BridgeAccessConfig(
            bridgeId: keys.hueBridgeId,
            ipAddress: keys.hueIP,
            username: keys.hueUsername)
    }()

    private let keys = HomeHubKeys()

    // MARK: - Public properties

    var healthy: Bool = false {
        didSet {
            if healthy != oldValue {
                log("Health Status changed: \(healthy)")
                delegate?.hueService(self, updateHealthStatus: healthy)
            }
        }
    }

    weak var delegate: HueServiceDelegate?

    // MARK: - Public Methods

    func updateLight(
        _ light: LightType,
        value: Float
    ) {
        var lightState = LightState()
        lightState.on = value > 0.0
        lightState.brightness = Int(value)

        log("Updating light \(light.toString) to \(lightState.brightness ?? -1)")
        sendAPI.updateLightStateForId(light.hueID, withLightState: lightState) { error in
            if let error = error {
                error.forEach { self.logError($0) }
            }
        }
    }

    // MARK: - Private methods

    private func updateLights(
        completion: @escaping () -> Void
    ) {
        resourceAPI.fetchLights { result in
            switch result {
            case let .success(lights):
                self.healthy = true
                if let officeLight = lights[LightType.office.hueID],
                    officeLight.state.reachable ?? false {
                    self.lights[.office] = officeLight
                } else {
                    self.lights[.office] = nil
                }
                
                if let foyerLight = lights[LightType.foyer.hueID],
                   foyerLight.state.reachable ?? false {
                    self.lights[.foyer] = foyerLight
                } else {
                    self.lights[.foyer] = nil
                }
                
                if let livingRoomLight = lights[LightType.livingRoom.hueID],
                   livingRoomLight.state.reachable ?? false {
                    self.lights[.livingRoom] = livingRoomLight
                } else {
                    self.lights[.livingRoom] = nil
                }

                self.propagateUpdatedLightValues()
            case let .failure(error):
                self.healthy = false
                self.logError(error)
            }

            completion()
        }
    }
    
    private func pollLights() {
        updateLights {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.pollLights()
            }
        }
    }

    private func propagateUpdatedLightValues() {
        let newDict: [LightType: Int?] = lights.mapValues {
            var value: Int?
            if let light = $0 {
                value = 0
                if light.state.on ?? false {
                    value = Int(light.state.brightness ?? 0)
                }
            }

            return value
        }
    
        self.delegate?.hueService(self, lightsUpdated: newDict)
    }
}
