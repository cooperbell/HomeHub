import Foundation
import SwiftyHue
import Keys

protocol HueServiceProtocol {
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
        lightsUpdated: [LightType: Light]
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
    
    private var lights: [LightType: Light] = [:]

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
            delegate?.hueService(self, updateHealthStatus: healthy)
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
                print(error)
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
                if let officeLight = lights[LightType.office.hueID]  {
                    self.lights[.office] = officeLight
                }
                
                if let foyerLight = lights[LightType.foyer.hueID]  {
                    self.lights[.foyer] = foyerLight
                }
                
                if let livingRoomLight = lights[LightType.livingRoom.hueID]  {
                    self.lights[.livingRoom] = livingRoomLight
                }

                self.delegate?.hueService(self, lightsUpdated: self.lights)
            case let .failure(error):
                self.healthy = false
                print("Updating light error: \(error.localizedDescription)")
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
}
