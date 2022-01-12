import Foundation
import UIKit

protocol MusicFullScreenViewModelProtocol {
    var albumCoverImage: UIImage? { get }
    var songTitleText: String? { get }
    var albumNameText: String? { get }
    var artistNameText: String? { get }
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

    // MARK: - Public properties

    var albumCoverImage: UIImage? {
        trackInfo.image
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
    
    var songProgress: Float? {
        trackInfo.progress
    }

    weak var viewControllerDelegate: MusicFullScreenViewModelViewControllerDelegate?
    
    private var dismissTimer: Timer?

    private func startDismissTimer() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { timer in
            self.viewControllerDelegate?.musicFullScreenViewModelDismissView(self)
        }
    }
}

// MARK: - HomeViewModelMusicFullScreenViewDelegate

extension MusicFullScreenViewModel: HomeViewModelMusicFullScreenViewDelegate {
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        trackInfoUpdated trackInfo: TrackInfo?
    ) {
        guard let trackInfo = trackInfo else {
            if dismissTimer == nil {
                startDismissTimer()
            }
            return
        }

        self.trackInfo = trackInfo
        if dismissTimer != nil {
            dismissTimer?.invalidate()
            dismissTimer = nil
        }
        
        viewControllerDelegate?.musicFullScreenViewModelRefreshView(self)
    }
}
