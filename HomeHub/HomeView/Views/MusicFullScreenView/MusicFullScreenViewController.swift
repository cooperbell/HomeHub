import UIKit

class MusicFullScreenViewController: UIViewController {

    @IBOutlet weak var musicBackgroundView: UIView!
    @IBOutlet weak var albumCoverImageView: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet weak var songProgressionProgressView: UIProgressView!

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        view.backgroundColor = .backgroundPrimaryDark
        setupMusicBackgroundView()
        setupLabels()
        setupProgressView()
        setTextOnLabels()
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
        artistLabel.textColor = .grayBlue
        albumNameLabel.textColor = .grayBlue
    }
    
    private func setupProgressView() {
        songProgressionProgressView.trackTintColor = .disabledGrayDark
        songProgressionProgressView.progressTintColor = .offWhite
        songProgressionProgressView.applyMaxCornerRadius()
    }
    
    private func setTextOnLabels() {
        songTitleLabel.text = "Send the Fisherman"
        artistLabel.text = "Caamp"
        albumNameLabel.text = "Boys (Side B)"
    }
    
    private func updateProgressView() {
        songProgressionProgressView.progress = 0.5
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
