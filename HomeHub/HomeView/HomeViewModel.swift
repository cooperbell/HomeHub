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
    var canPresentMusicFullScreenView: Bool { get }
    var viewControllerDelegate: HomeViewModelViewControllerDelegate? { get set }
    var musicFullScreenViewDelegate: HomeViewModelMusicFullScreenViewDelegate? { get set }
    
    func numberOfItemsInSection(_ section: Int) -> Int
    func getManageLightViewCellViewModel(at indexPath: IndexPath) -> ManageLightViewCellViewModelProtocol?
    func getMusicFullScreenViewModel() -> MusicFullScreenViewModelProtocol?
    func lockActionButtonTapped()
}

protocol HomeViewModelViewControllerDelegate: AnyObject {
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        updateHealthStatusViewFor viewContext: ViewContext
    )
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        updateSliderValue value: Float?,
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

protocol HomeViewModelMusicFullScreenViewDelegate: AnyObject {
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        trackInfoUpdated trackInfo: TrackInfo?
    )
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
        hueService = LightsService(delegate: self)
        lockService = AugustLockService(delegate: self)
        musicService = MusicService(delegate: self)
        startTimer()
    }

    // MARK: - Private properties

    private var lockState: LockState? {
        lockService.lockState
    }

    private var hueService: LightsServiceProtocol!

    private var lockService: AugustLockServiceProtocol!

    private var musicService: MusicServiceProtocol!

    private var smartLightDataSource: [(lightType: LightType, value: Int?)] =
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
        guard let trackInfo = musicService.trackInfo else {
            return UIImage(named: "spotifyNonePlaying")
        }
        return trackInfo.albumImage ?? UIImage(named: "spotifyNonePlaying")
    }

    var songTitleText: String? {
        musicService.trackInfo?.name
    }
    
    var artistNameText: String? {
        musicService.trackInfo?.artist
    }
    
    var songProgressionValue: Float? {
        musicService.trackInfo?.progress
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

    var canPresentMusicFullScreenView: Bool {
        musicService.trackInfo != nil
    }

    weak var viewControllerDelegate: HomeViewModelViewControllerDelegate?

    weak var musicFullScreenViewDelegate: HomeViewModelMusicFullScreenViewDelegate?

    // MARK: - Public Methods
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        smartLightDataSource.count
    }
    
    func getManageLightViewCellViewModel(
        at indexPath: IndexPath
    ) -> ManageLightViewCellViewModelProtocol? {
        let dataSourceElement = smartLightDataSource[indexPath.row]
        let light = dataSourceElement.lightType
        let brightness = dataSourceElement.value

        let smartLightData = SmartLightData(light: light, value: brightness)
        return ManageLightViewCellViewModel(smartLightData: smartLightData, delegate: self)
    }

    func getMusicFullScreenViewModel() -> MusicFullScreenViewModelProtocol? {
        guard let trackInfo = musicService.trackInfo else {
            return nil
        }

        let viewModel = MusicFullScreenViewModel(trackInfo: trackInfo)
        musicFullScreenViewDelegate = viewModel

        return viewModel
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

    private func getHealthStatusColorFrom(
        _ healthy: Bool
    ) -> UIColor {
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

// MARK: - LightsServiceDelegate

extension HomeViewModel: LightsServiceDelegate {
    func lightsService(
        _ lightsService: LightsService,
        updateHealthStatus healthy: Bool
    ) {
        viewControllerDelegate?.homeViewModel(self, updateHealthStatusViewFor: .lights)
    }

    func lightsService(
        _ lightsService: LightsService,
        lightsUpdated lightData: [LightType: Int?]
    ) {
        smartLightDataSource.enumerated().forEach { (index, _) in
            updateLightIfNeeded(at: index, lightData: lightData )
        }
    }
    
    private func updateLightIfNeeded(
        at index: Int,
        lightData: [LightType: Int?]
    ) {
        let indexPath = IndexPath(row: index, section: 0)
        let lightType = smartLightDataSource[index].lightType
        guard
            let value = lightData[lightType],
            let newLightValue = value
        else {
            smartLightDataSource[index].value = nil
            viewControllerDelegate?.homeViewModel(self, updateSliderValue: nil, at: indexPath)
            return
        }
        
        let currentLightValue = smartLightDataSource[index].value
        smartLightDataSource[index].value = newLightValue
        
        guard currentLightValue != newLightValue else {
            return
        }

        let sliderValue = Float(newLightValue)
        viewControllerDelegate?.homeViewModel(self, updateSliderValue: sliderValue, at: indexPath)
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
        musicFullScreenViewDelegate?.homeViewModel(
            self,
            trackInfoUpdated: musicService.trackInfo)
    }
}
