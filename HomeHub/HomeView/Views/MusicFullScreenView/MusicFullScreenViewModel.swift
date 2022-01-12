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
}

// MARK: - HomeViewModelMusicFullScreenViewDelegate

extension MusicFullScreenViewModel: HomeViewModelMusicFullScreenViewDelegate {
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        trackInfoUpdated trackInfo: TrackInfo
    ) {
        self.trackInfo = trackInfo
        viewControllerDelegate?.musicFullScreenViewModelRefreshView(self)
    }
}
