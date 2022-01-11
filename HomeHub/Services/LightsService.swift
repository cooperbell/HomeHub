import Foundation
import SwiftyHue

protocol LightsServiceProtocol {
    typealias LightData = [LightType: Light?]

    var healthy: Bool { get set }
    var delegate: LightsServiceDelegate? { get set }
    
    func updateLight(_ light: LightType, value: Float)
}

protocol LightsServiceDelegate: AnyObject {
    func lightsService(
        _ lightsService: LightsService,
        updateHealthStatus healthy: Bool
    )
    
    func lightsService(
        _ lightsService: LightsService,
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

class LightsService: LightsServiceProtocol, LoggerProtocol {
    // MARK: - Init

    init(delegate: LightsServiceDelegate? = nil) {
        self.delegate = delegate
        pollLights()
    }

    // MARK: - Private properties

    private var lights: LightData = [
        .foyer: nil,
        .livingRoom: nil,
        .office: nil
    ]

    private let hueWrapper = PhillipsHueWrapper()

    // MARK: - Public properties

    var healthy: Bool = false {
        didSet {
            if healthy != oldValue {
                log("Health Status changed: \(healthy)")
                delegate?.lightsService(self, updateHealthStatus: healthy)
            }
        }
    }

    weak var delegate: LightsServiceDelegate?

    // MARK: - Public Methods

    func updateLight(
        _ light: LightType,
        value: Float
    ) {
        var lightState = LightState()
        lightState.on = value > 0.0
        lightState.brightness = Int(value)

        log("Updating light \(light.toString) to \(lightState.brightness ?? -1)")
        hueWrapper.updateLight(id: light.hueID, value: value) { error in
            if let error = error {
                self.logError(error)
            }
        }
    }

    // MARK: - Private methods

    private func pollLights() {
        updateLights {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.pollLights()
            }
        }
    }

    private func updateLights(
        completion: @escaping () -> Void
    ) {
        hueWrapper.fetchLights { lights, error in
            guard let lights = lights, error == nil else {
                self.healthy = false
                self.logError(error)
                self.lights[.office] = nil
                self.lights[.foyer] = nil
                self.lights[.livingRoom] = nil
                self.propagateUpdatedLightValues()
                completion()
                return
            }
            
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
    
        self.delegate?.lightsService(self, lightsUpdated: newDict)
    }
}
