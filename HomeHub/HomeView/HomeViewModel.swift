import Foundation
import UIKit
import SwiftyHue

protocol HomeViewModelProtocol {
    var greetingText: String { get }
    var currentTimeText: String { get }
    var frontDoorLockImage: UIImage? { get }
    var frontDoorLockStatusText: String { get }
    var albumCoverImage: UIImage? { get }
    var songTitleText: String? { get }
    var artistNameText: String? { get }
    var songProgressionValue: Float? { get }
    var lightsHealthMonitorColor: UIColor { get }
    var lockServiceHealthMonitorColor: UIColor { get }
    var musicServiceHealthMonitorColor: UIColor { get }
    var viewControllerDelegate: HomeViewModelViewControllerDelegate? { get set }
    
    func numberOfItemsInSection(_ section: Int) -> Int
    func getManageLightViewCellViewModel(at indexPath: IndexPath) -> ManageLightViewCellViewModelProtocol?
    func lockActionButtonTapped()
}

protocol HomeViewModelViewControllerDelegate: AnyObject {
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        updateHealthStatusViewFor viewContext: ViewContext
    )
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        updateSliderValue value: Float,
        at indexPath: IndexPath
    )
    func homeViewModelUpdateLabels(_ homeViewModel: HomeViewModelProtocol)
    func homeViewModelUpdateLockView(_ homeViewModel: HomeViewModelProtocol)
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        toggleLockViewLoading on: Bool
    )
    func homeViewModelUpdateMusicLabels(_ homeViewModel: HomeViewModelProtocol)
}

enum ViewContext {
    case lights
    case locks
    case music
}

class HomeViewModel: HomeViewModelProtocol {
    // MARK: - Init

    init(delegate: HomeViewModelViewControllerDelegate? = nil) {
        self.viewControllerDelegate = delegate
        hueService = HueService(delegate: self)
        lockService = AugustLockService(delegate: self)
        musicService = MusicService(delegate: self)
        startTimer()
    }

    // MARK: - Private properties

    private var lockState: LockState? {
        lockService.lockState
    }

    private var hueService: HueServiceProtocol!

    private var lockService: AugustLockServiceProtocol!

    private var musicService: MusicServiceProtocol!

    private var smartLightDataSource: [(lightType: LightType, light: Light?)] =
        [
            (.foyer, nil),
            (.livingRoom, nil),
            (.office, nil)
        ]

    // MARK: - Public properties

    var greetingText: String {
        var message = ""
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            message = "Good morning"
        case 12..<18:
            message = "Good afternoon"
        case 18..<24:
            message = "Good evening"
        default:
            message = "Hello"
        }

        message.append(", Cooper")

        return message
    }
    
    var currentTimeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"

        return formatter.string(from: Date())
    }
    
    var frontDoorLockImage: UIImage? {
        lockState?.associatedImage ?? UIImage(named: "lockUnknown")
    }
    
    var frontDoorLockStatusText: String {
        lockState?.formattedString ?? "Unknown"
    }

    var albumCoverImage: UIImage? {
        musicService.trackInfo.image ??
        UIImage(named: "spotifyNonePlaying")
    }

    var songTitleText: String? {
        musicService.trackInfo.name
    }
    
    var artistNameText: String? {
        musicService.trackInfo.artist
    }
    
    var songProgressionValue: Float? {
        musicService.trackInfo.progress
    }

    var lightsHealthMonitorColor: UIColor {
        getHealthStatusColorFrom(hueService.healthy)
    }

    var lockServiceHealthMonitorColor: UIColor {
        getHealthStatusColorFrom(lockService.healthy)
    }
    
    var musicServiceHealthMonitorColor: UIColor {
        getHealthStatusColorFrom(musicService.healthy)
    }

    weak var viewControllerDelegate: HomeViewModelViewControllerDelegate?

    // MARK: - Public Methods
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        smartLightDataSource.count
    }
    
    func getManageLightViewCellViewModel(
        at indexPath: IndexPath
    ) -> ManageLightViewCellViewModelProtocol? {
        let dataSourceElement = smartLightDataSource[indexPath.row]
        var brightness: Int = 0
        if let light = dataSourceElement.light, light.state.on ?? false {
            brightness = light.state.brightness ?? 0
        }

        let smartLightData = SmartLightData(light: dataSourceElement.lightType, value: brightness)
        return ManageLightViewCellViewModel(smartLightData: smartLightData, delegate: self)
    }

    func lockActionButtonTapped() {
        viewControllerDelegate?.homeViewModel(self, toggleLockViewLoading: true)
        lockService.toggleLockState {
            self.viewControllerDelegate?.homeViewModel(self, toggleLockViewLoading: false)
        }
    }

    // MARK: - Private methods

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            self.viewControllerDelegate?.homeViewModelUpdateLabels(self)
        }
    }

    private func getHealthStatusColorFrom(_ healthy: Bool) -> UIColor {
        healthy ? .clear : .homeHubRed
    }
}

// MARK: - ManageLightViewCellViewModelDelegate

extension HomeViewModel: ManageLightViewCellViewModelDelegate {
    func manageLightViewCellViewModel(
        _ manageLightViewCellViewModel: ManageLightViewCellViewModelProtocol,
        sliderValueUpdated value: Float,
        forLight light: LightType
    ) {
        hueService.updateLight(light, value: value)
    }
}

extension HomeViewModel: HueServiceDelegate {
    func hueService(
        _ hueService: HueService,
        updateHealthStatus healthy: Bool
    ) {
        viewControllerDelegate?.homeViewModel(self, updateHealthStatusViewFor: .lights)
    }

    func hueService(
        _ hueService: HueService,
        lightsUpdated lightData: [LightType : Light]
    ) {
        lightData.forEach { dictElement in
            let index = smartLightDataSource.firstIndex {
                $0.lightType == dictElement.key
            }

            if let index = index {
                let currentLightState = smartLightDataSource[index].light?.state
                let newLightState = dictElement.value.state
                if currentLightState?.brightness != newLightState.brightness ||
                    currentLightState?.on != newLightState.on {
                    smartLightDataSource[index].light = dictElement.value
                    var value: Float = 0.0
                    if dictElement.value.state.on ?? false {
                        value = Float(newLightState.brightness ?? 0)
                    }
                    let indexPath = IndexPath(row: index, section: 0)
                    viewControllerDelegate?.homeViewModel(self, updateSliderValue: value, at: indexPath)
                }
            }
        }
    }
}

// MARK: - AugustLockServiceDelegate

extension HomeViewModel: AugustLockServiceDelegate {
    func augustLockServiceUpdateHealthStatus(
        _ augustLockService: AugustLockService
    ) {
        viewControllerDelegate?.homeViewModel(self, updateHealthStatusViewFor: .locks)
    }
    
    func augustLockService(
        _ augustLockService: AugustLockService,
        lockedStateUpdated lockState: LockState?
    ) {
        viewControllerDelegate?.homeViewModelUpdateLockView(self)
    }
}

// MARK: - MusicServiceDelegate

extension HomeViewModel: MusicServiceDelegate {
    func musicServiceUpdateHealthStatus(
        _ musicService: MusicService
    ) {
        viewControllerDelegate?.homeViewModel(
            self,
            updateHealthStatusViewFor: .music)
    }

    func musicServiceTrackInfoUpdated(
        _ musicService: MusicService
    ) {
        viewControllerDelegate?.homeViewModelUpdateMusicLabels(self)
    }
}
