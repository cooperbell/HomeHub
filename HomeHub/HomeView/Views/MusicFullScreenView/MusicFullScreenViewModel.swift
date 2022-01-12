import Foundation
import UIKit

protocol MusicFullScreenViewModelProtocol {
    var albumCoverImage: UIImage? { get }
    var songTitleText: String? { get }
    var artistNameText: String? { get }
    var songProgressionValue: Float? { get }
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
    
    var artistNameText: String? {
        trackInfo.artist
    }
    
    var songProgressionValue: Float? {
        trackInfo.progress
    }
}
