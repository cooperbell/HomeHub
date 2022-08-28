import Foundation
import UIKit

protocol MusicFullScreenViewModelProtocol {
    var albumCoverImage: UIImage? { get }
    var songTitleText: String? { get }
    var albumNameText: String? { get }
    var artistNameText: String? { get }
    var artistImage: UIImage? { get }
    var songProgress: Float? { get }
    var viewControllerDelegate: MusicFullScreenViewModelViewControllerDelegate? { get set }
}

protocol MusicFullScreenViewModelViewControllerDelegate: AnyObject {
    func musicFullScreenViewModelRefreshView(
        _ musicFullScreenViewModel: MusicFullScreenViewModelProtocol
    )
    
    func musicFullScreenViewModelDismissView(
        _ musicFullScreenViewModel: MusicFullScreenViewModelProtocol
    )
}

class MusicFullScreenViewModel: MusicFullScreenViewModelProtocol {
    // MARK: - Init

    init(trackInfo: TrackInfo) {
        self.trackInfo = trackInfo
    }

    // MARK: - Private propertis
    
    private var trackInfo: TrackInfo

    private var dismissTimer: Timer?

    // MARK: - Public properties

    var albumCoverImage: UIImage? {
        trackInfo.albumImage
    }

    var songTitleText: String? {
        trackInfo.name
    }
    
    var albumNameText: String? {
        trackInfo.albumName
    }

    var artistNameText: String? {
        trackInfo.artist
    }

    var artistImage: UIImage? {
        trackInfo.artistImage
    }

    var songProgress: Float? {
        trackInfo.progress
    }

    weak var viewControllerDelegate: MusicFullScreenViewModelViewControllerDelegate?
    
    // MARK: - Private methods

    private func startDismissTimerIfNeeded() {
        guard dismissTimer == nil else {
            return
        }

        dismissTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: false) { timer in
            self.viewControllerDelegate?.musicFullScreenViewModelDismissView(self)
        }
    }
    
    private func stopDismissTimerIfNeeded() {
        guard dismissTimer != nil else {
            return
        }
        
        dismissTimer?.invalidate()
        dismissTimer = nil
    }
}

// MARK: - HomeViewModelMusicFullScreenViewDelegate

extension MusicFullScreenViewModel: HomeViewModelMusicFullScreenViewDelegate {
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        trackInfoUpdated trackInfo: TrackInfo?
    ) {
        guard let trackInfo = trackInfo else {
            startDismissTimerIfNeeded()
            return
        }

        self.trackInfo = trackInfo
        stopDismissTimerIfNeeded()
        viewControllerDelegate?.musicFullScreenViewModelRefreshView(self)
    }
}
