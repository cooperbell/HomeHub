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
    var albumImage: UIImage?
    var artist: String?
    var artistImage: UIImage?
    var duration: Int?
    var progress: Float?
    var isPlaying: Bool?
}

enum MusicImageType: String {
    case album
    case artist
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
        startSongProgressionInterpolationTimer()
    }

    // MARK: - Private properties

    private var spotify = SpotifyAPIWrapper()

    private var cancellables: Set<AnyCancellable> = []

    private var currentAlbumImageURL: URL?

    private var currentArtistImageURL: URL?

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

    private func startSongProgressionInterpolationTimer() {
        let delta = 0.1
        Timer.scheduledTimer(withTimeInterval: delta, repeats: true) { timer in
            self.updateTrackProgress(delta: delta)
        }
    }

    private func loadCurrentlyPlaying(
        completion: (() -> Void)? = nil
    ) {
        spotify.api
            .currentPlayback()
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: {
                    self.receiveCompletion($0) { completion?() }
                },
                receiveValue: {
                    self.handleCurrentlyPlayingContext($0) { completion?() }
                }
            )
            .store(in: &cancellables)
    }
    
    private func updateTrackProgress(delta: Double) {
        guard
            trackInfo?.isPlaying ?? false,
            let durationMS = trackInfo?.duration,
            let progress = trackInfo?.progress
        else {
            return
        }

        let interpolatedProgress = self.calculateInterpolatedSongProgress(
            progress: progress,
            durationMS: durationMS,
            delta: delta)
        self.trackInfo?.progress = interpolatedProgress
        self.delegate?.musicServiceTrackInfoUpdated(self)
    }
    
    private func handleCurrentlyPlayingContext(
        _ currentlyPlayingContext: CurrentlyPlayingContext?,
        completion: @escaping () -> Void
    ) {
        if trackInfo == nil {
            trackInfo = TrackInfo()
        }

        guard let currentlyPlayingContext = currentlyPlayingContext else {
            healthy = true
            trackInfo = nil
            currentAlbumImageURL = nil
            delegate?.musicServiceTrackInfoUpdated(self)
            completion()
            return
        }

        let item = currentlyPlayingContext.item

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

        spotify.api.track(uri)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: {
                    self.receiveCompletion($0) { completion() }
                },
                receiveValue: { track in
                    self.healthy = true
                    let progressMS = currentlyPlayingContext.progressMS
                    let durationMS = item?.durationMS
                    let isPlaying = currentlyPlayingContext.isPlaying

                    self.updateTrackInfo(
                        track,
                        name: trackName,
                        progressMS: progressMS,
                        durationMS: durationMS,
                        isPlaying: isPlaying)

                    completion()
                }
            )
            .store(in: &cancellables)
    }

    private func updateTrackInfo(
        _ track: Track,
        name: String,
        progressMS: Int?,
        durationMS: Int?,
        isPlaying: Bool?
    ) {
        trackInfo?.name = name
        trackInfo?.albumName = track.album?.name
        trackInfo?.isPlaying = isPlaying

        if let artists = track.artists {
            let artistNames = artists
                .map { $0.name }
                .joined(separator: ", ")
            trackInfo?.artist = artistNames
            
            if let artistId = artists.first?.id {
                fetchArtist(id: artistId) { artist in
                    if let artistImageUrl = artist?.images?.largest?.url,
                       artistImageUrl != self.currentArtistImageURL {
                        self.currentArtistImageURL = artistImageUrl
                        self.fetchImage(ofType: .artist, from: artistImageUrl)
                    }
                }
            }
            
        } else {
            trackInfo?.artist = nil
        }

        if let albumImageUrl = track.album?.images?.largest?.url,
            albumImageUrl != currentAlbumImageURL {
            currentAlbumImageURL = albumImageUrl
            fetchImage(ofType: .album, from: albumImageUrl)
        }

        if let progressMS = progressMS,
            let durationMS = durationMS,
            durationMS > 0 {
            let progress = Float(progressMS) / Float(durationMS)
            trackInfo?.duration = durationMS
            trackInfo?.progress = progress
        } else {
            trackInfo?.duration = nil
            trackInfo?.progress = nil
        }

        delegate?.musicServiceTrackInfoUpdated(self)
    }
    
//    private func fetchTrackImage(from url: URL) {
//        log("fetching track image")
//        Alamofire.request(url).response { response in
//            guard
//                let data = response.data
//            else {
//                self.trackInfo?.albumImage = nil
//                return
//            }
//
//            let image = UIImage(data: data)
//            self.trackInfo?.albumImage = image
//            self.delegate?.musicServiceTrackInfoUpdated(self)
//        }
//    }
    
    private func fetchImage(ofType type: MusicImageType, from url: URL) {
        log("fetching \(type.rawValue) image")
        Alamofire.request(url).response { response in
            guard
                let data = response.data
            else {
                self.trackInfo?.albumImage = nil
                return
            }
            
            let image = UIImage(data: data)
            switch type {
            case .album:
                self.trackInfo?.albumImage = image
            case .artist:
                self.trackInfo?.artistImage = image
            }
            self.delegate?.musicServiceTrackInfoUpdated(self)
        }
    }
    
    private func fetchArtist(
        id: String,
        completion: @escaping (Artist?) -> Void
    ) {
        let spotifyUrl = "spotify:artist:\(id)"
        spotify.api.artist(spotifyUrl)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: {
                    self.receiveCompletion($0) { completion(nil) }
                },
                receiveValue: { completion($0) }
            )
            .store(in: &cancellables)
    }
    
    private func receiveCompletion(
        _ receivedCompletion: Subscribers.Completion<Error>,
        completion: @escaping () -> Void
    ) {
        guard case let .failure(error) = receivedCompletion else {
            return
        }

        healthy = false
        logError(error)
        completion()
    }

    private func calculateInterpolatedSongProgress(
        progress: Float,
        durationMS: Int,
        delta: Double
    ) -> Float {
        let durationS = Float(durationMS) / 1000.0
        let percentDelta = Float(100.0 / durationS)
        let percentDeltaQuartered = (percentDelta * Float(delta)) / 100.0
        let interpolatedProgress = progress + percentDeltaQuartered

        return interpolatedProgress > 1.0 ? 1.0 : interpolatedProgress
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
        
        spotify
            .api
            .authorizationManager
            .requestAccessAndRefreshTokens(
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
        
        spotify.authorizationState = String.randomURLSafe(length: 128)
    }
}
