import UIKit
import MarqueeLabel

class MusicFullScreenViewController: UIViewController {
    // MARK: - Outlets

    @IBOutlet weak var musicBackgroundView: UIView!
    @IBOutlet weak var albumCoverImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: MarqueeLabel!
    @IBOutlet weak var artistLabel: MarqueeLabel!
    @IBOutlet weak var albumNameLabel: MarqueeLabel!
    @IBOutlet weak var songProgressionProgressView: UIProgressView!

    // MARK: - Public properties

    override var prefersStatusBarHidden: Bool {
        return true
    }

    var viewModel: MusicFullScreenViewModelProtocol?

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    // MARK: - Setup methods

    private func setup() {
        viewModel?.viewControllerDelegate = self
        view.backgroundColor = .backgroundPrimaryDark
        setupMusicBackgroundView()
        setupLabels()
        setupProgressView()
        setTextOnLabels()
        updateAlbumCover()
        updateProgressView()
        setupViewTapGestureRecognizer()
    }
    
    private func setupMusicBackgroundView() {
        musicBackgroundView.backgroundColor = .backgroundSecondaryDark
        musicBackgroundView.applyCornerRadius(25)
        albumCoverImageView.applyCornerRadius(10)
    }
    
    private func setupLabels() {
        songTitleLabel.textColor = .offWhite
        songTitleLabel.type = .leftRight

        artistLabel.textColor = .grayBlue
        artistLabel.type = .leftRight

        albumNameLabel.textColor = .grayBlue
        albumNameLabel.type = .leftRight
    }
    
    private func setupProgressView() {
        songProgressionProgressView.trackTintColor = .disabledGrayDark
        songProgressionProgressView.progressTintColor = .offWhite
        songProgressionProgressView.applyMaxCornerRadius()
    }
    
    private func setTextOnLabels() {
        songTitleLabel.text = viewModel?.songTitleText
        artistLabel.text = viewModel?.artistNameText
        albumNameLabel.text = viewModel?.albumNameText
    }
    
    private func updateAlbumCover() {
        albumCoverImageView.image = viewModel?.albumCoverImage
    }

    private func updateProgressView() {
        songProgressionProgressView.progress = viewModel?.songProgress ?? 0.0
    }
    
    private func setupViewTapGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(viewTapped))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    // MARK: - Callbacks

    @objc func viewTapped(
        _ gestureRecognizer: UITapGestureRecognizer
    ) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - MusicFullScreenViewModelViewControllerDelegate

extension MusicFullScreenViewController: MusicFullScreenViewModelViewControllerDelegate {
    func musicFullScreenViewModelRefreshView(
        _ musicFullScreenViewModel: MusicFullScreenViewModelProtocol
    ) {
        setTextOnLabels()
        updateAlbumCover()
        updateProgressView()
    }
}
