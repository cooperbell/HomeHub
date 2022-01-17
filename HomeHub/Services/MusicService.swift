import Foundation
import Alamofire
import UIKit
import Combine
import SpotifyWebAPI

protocol MusicServiceProtocol {
    var trackInfo: TrackInfo? { get set }
    var healthy: Bool { get set }
    var delegate: MusicServiceDelegate? { get set }
}

protocol MusicServiceDelegate: AnyObject {
    func musicServiceUpdateHealthStatus(
        _ musicService: MusicService
    )
    
    func musicServiceTrackInfoUpdated(
        _ musicService: MusicService
    )
}

struct TrackInfo {
    var name: String?
    var albumName: String?
    var artist: String?
    var image: UIImage?
    var progress: Float?
}

class MusicService: MusicServiceProtocol, LoggerProtocol {
    // MARK: - Init

    init(delegate: MusicServiceDelegate? = nil) {
        self.delegate = delegate
        // vv I run this manually when needed. So far only once
//        spotify.authorize()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(receiveSpotifyAuthURL),
            name: SpotifyAPIWrapper.authURLNotif,
            object: nil)

        pollCurrentlyPlaying()
    }

    // MARK: - Private properties

    private var spotify = SpotifyAPIWrapper()

    private var cancellables: Set<AnyCancellable> = []

    private var currentAlbumImageURL: URL?
    
    // MARK: - Public properties

    var trackInfo: TrackInfo?

    var healthy: Bool = false {
        didSet {
            if healthy != oldValue {
                log("Health Status changed: \(healthy)")
                delegate?.musicServiceUpdateHealthStatus(self)
            }
        }
    }

    weak var delegate: MusicServiceDelegate?

    // MARK: - Private methods

    private func pollCurrentlyPlaying() {
        loadCurrentlyPlaying {
            self.wait {
                self.pollCurrentlyPlaying()
            }
        }
    }

    private func loadCurrentlyPlaying(
        completion: (() -> Void)? = nil
    ) {
        spotify.api
            .currentPlayback(market: nil)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveCompletion(_:),
                receiveValue: {
                    self.handleCurrentlyPlayingContext($0) { completion?() }
                }
            )
            .store(in: &cancellables)
    }
    
    private func handleCurrentlyPlayingContext(
        _ currentlyPlaying: CurrentlyPlayingContext?,
        completion: @escaping () -> Void
    ) {
        if trackInfo == nil {
            trackInfo = TrackInfo()
        }

        guard let currentlyPlaying = currentlyPlaying else {
            healthy = true
            trackInfo = nil
            currentAlbumImageURL = nil
            delegate?.musicServiceTrackInfoUpdated(self)
            completion()
            return
        }

        let item = currentlyPlaying.item

        guard
            let trackName = item?.name,
            let uri = item?.uri
        else {
            healthy = false
            trackInfo = nil
            currentAlbumImageURL = nil
            delegate?.musicServiceTrackInfoUpdated(self)
            completion()
            return
        }

        spotify.api.track(uri, market: nil)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: self.receiveCompletion(_:),
                receiveValue: { track in
                    self.healthy = true
                    let progressMS = currentlyPlaying.progressMS
                    let durationMS = item?.durationMS

                    self.updateTrackInfo(
                        track,
                        name: trackName,
                        progressMS: progressMS,
                        durationMS: durationMS)

                    completion()
                }
            )
            .store(in: &cancellables)
    }

    private func updateTrackInfo(
        _ track: Track,
        name: String,
        progressMS: Int?,
        durationMS: Int?
    ) {
        trackInfo?.name = name
        trackInfo?.albumName = track.album?.name

        if let artists = track.artists {
            let artistNames = artists
                .map { $0.name }
                .joined(separator: ", ")
            trackInfo?.artist = artistNames
        } else {
            trackInfo?.artist = nil
        }

        if let albumImageUrl = track.album?.images?.largest?.url,
            albumImageUrl != currentAlbumImageURL {
            currentAlbumImageURL = albumImageUrl
            fetchTrackImage(from: albumImageUrl)
        }

        if let progressMS = progressMS,
            let durationMS = durationMS,
            durationMS > 0 {
            let progress = Float(progressMS) / Float(durationMS)
            trackInfo?.progress = progress
        } else {
            trackInfo?.progress = nil
        }

        delegate?.musicServiceTrackInfoUpdated(self)
    }
    
    private func fetchTrackImage(from url: URL) {
        log("fetching track image")
        Alamofire.request(url).response { response in
            guard
                let data = response.data
            else {
                self.trackInfo?.image = nil
                return
            }
            
            let image = UIImage(data: data)
            self.trackInfo?.image = image
            self.delegate?.musicServiceTrackInfoUpdated(self)
        }
    }
    
    private func receiveCompletion(
        _ completion: Subscribers.Completion<Error>
    ) {
        guard case let .failure(error) = completion else {
            return
        }

        healthy = false
        logError(error)
    }

    private func wait(
        completion: @escaping (() -> Void)
    ) {
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1.5
        ) { completion() }
    }

    // MARK: - Callbacks
    
    @objc func receiveSpotifyAuthURL(notification: NSNotification) {
        guard let url = notification.object as? URL else {
            return
        }
        
        spotify.api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            state: spotify.authorizationState
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                self.logError(error)
            } else {
                self.pollCurrentlyPlaying()
            }
        })
        .store(in: &cancellables)
        
        self.spotify.authorizationState = String.randomURLSafe(length: 128)
    }
}
