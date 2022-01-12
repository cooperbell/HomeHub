import UIKit
import MediaPlayer
import MarqueeLabel

class HomeViewController: UIViewController {
    // MARK: - Outlets

    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var lightsBackgroundView: UIView!
    @IBOutlet weak var lightsCollectionView: UICollectionView!
    @IBOutlet weak var lightsViewHealthStatusView: UIView!
    @IBOutlet weak var lockBackgroundView: UIView!
    @IBOutlet weak var musicBackgroundView: UIView!
    @IBOutlet weak var frontDoorLockBackgroundView: UIView!
    @IBOutlet weak var lockServiceHealthStatusView: UIView!
    @IBOutlet weak var frontDoorLockImageView: UIImageView!
    @IBOutlet weak var frontDoorLockStateLabel: UILabel!
    @IBOutlet weak var lockActionButton: UIButton!
    @IBOutlet weak var musicServiceHealthStatusView: UIView!
    @IBOutlet weak var musicAlbumCoverImageView: UIImageView!
    @IBOutlet weak var musicViewSongTitleLabel: MarqueeLabel!
    @IBOutlet weak var musicViewArtistLabel: MarqueeLabel!
    @IBOutlet weak var musicViewProgressView: UIProgressView!
    @IBOutlet weak var spinnerView: UIActivityIndicatorView!
    
    // MARK: - Private properties

    private var lockState = LockState.locked

    // MARK: - Public properties

    override var prefersStatusBarHidden: Bool {
        return true
    }

    var viewModel: HomeViewModelProtocol?

    // MARK: - Lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }

    // MARK: - Setup methods

    private func setup() {
        viewModel = HomeViewModel(delegate: self)
        setupGreetingLabel()
        setupCurrentTimeLabel()
        view.backgroundColor = .backgroundPrimaryDark
        setupLightsBackgroundView()
        setupLightsCollectionView()
        setupLockBackgroundView()
        setupMusicBackgroundView()
        spinnerView.hidesWhenStopped = true
    }

    private func setupGreetingLabel() {
        greetingLabel.text = viewModel?.greetingText
        greetingLabel.textColor = .offWhite
    }

    private func setupCurrentTimeLabel() {
        currentTimeLabel.text = viewModel?.currentTimeText
        currentTimeLabel.textColor = .offWhite
    }

    private func setupLightsBackgroundView() {
        lightsBackgroundView.backgroundColor = .backgroundSecondaryDark
        lightsBackgroundView.layer.cornerRadius = 25
        lightsViewHealthStatusView.applyMaxCornerRadius()
        updateLightsViewHealthStatusView()
    }
    
    private func setupLightsCollectionView() {
        lightsCollectionView.dataSource = self
        lightsCollectionView.delegate = self
        lightsCollectionView.backgroundColor = .clear
        setupCollectionViewLayout()

        lightsCollectionView.registerCell(ofType: ManageLightViewCell.self)
    }

    private func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        let height = lightsBackgroundView.bounds.height * 0.96
        layout.itemSize = CGSize(width: height * 0.34, height: height)
        lightsCollectionView.collectionViewLayout = layout
    }

    private func setupLockBackgroundView() {
        lockBackgroundView.backgroundColor = .backgroundSecondaryDark
        lockBackgroundView.applyCornerRadius(25)
        updateLockServiceHealthStatusView()
        setupFrontDoorLockView()
    }
    
    private func setupFrontDoorLockView() {
        frontDoorLockBackgroundView.backgroundColor = .disabledGrayDark
        frontDoorLockBackgroundView.applyCornerRadius(21)
        lockServiceHealthStatusView.applyCornerRadius(2.5)
        frontDoorLockBackgroundView.clipsToBounds = true
        frontDoorLockStateLabel.textColor = .offWhite

        updateFrontDoorLockViewSubviews()
    }

    private func setupMusicBackgroundView() {
        musicBackgroundView.backgroundColor = .backgroundSecondaryDark
        musicBackgroundView.applyCornerRadius(25)
        musicServiceHealthStatusView.applyMaxCornerRadius()

        musicAlbumCoverImageView.applyCornerRadius(10)

        musicViewSongTitleLabel.textColor = .offWhite
        musicViewSongTitleLabel.type = .leftRight
        musicViewSongTitleLabel.animationDelay = 3
        musicViewSongTitleLabel.trailingBuffer = 20
        
        musicViewArtistLabel.type = .leftRight
        musicViewArtistLabel.animationDelay = 3
        musicViewArtistLabel.trailingBuffer = 20

        musicViewProgressView.trackTintColor = .disabledGrayDark
        musicViewProgressView.progressTintColor = .offWhite
        musicViewProgressView.applyMaxCornerRadius()

        setupViewTapGestureRecognizer()
    
        updateMusicView()
        updateMusicServiceHealthStatusView()
    }
    
    private func setupViewTapGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(musicViewTapped))
        musicBackgroundView.addGestureRecognizer(tapRecognizer)
    }

    private func updateMusicView() {
        musicAlbumCoverImageView.image = viewModel?.albumCoverImage
        musicViewSongTitleLabel.text = viewModel?.songTitleText
        musicViewArtistLabel.text = viewModel?.artistNameText

        if let progress = viewModel?.songProgressionValue {
            musicViewProgressView.isHidden = false
            musicViewProgressView.progress = progress
        } else {
            musicViewProgressView.isHidden = true
        }
    }

    // MARK: - Private methods

    private func updateLightsViewHealthStatusView() {
        lightsViewHealthStatusView.backgroundColor = viewModel?.lightsHealthMonitorColor
    }
    
    private func updateLockServiceHealthStatusView() {
        lockServiceHealthStatusView.backgroundColor = viewModel?.lockServiceHealthMonitorColor
    }

    private func updateMusicServiceHealthStatusView() {
        musicServiceHealthStatusView.backgroundColor = viewModel?.musicServiceHealthMonitorColor
    }

    private func updateFrontDoorLockViewSubviews() {
        frontDoorLockImageView.image = viewModel?.frontDoorLockImage
        frontDoorLockStateLabel.text = viewModel?.frontDoorLockStatusText
    }

    // MARK: - Navigation functions

    private func navigateToMusicFullScreenView() {
        guard
            let vc: MusicFullScreenViewController = UIStoryboard.instantiateTypedVC()
        else {
            return
        }

        vc.viewModel = viewModel?.getMusicFullScreenViewModel()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true, completion: nil)
    }

    // MARK: - Callbacks

    @IBAction func lockActionButtonTapped(_ sender: Any) {
        viewModel?.lockActionButtonTapped()
    }

    @objc func musicViewTapped(
        _ gestureRecognizer: UITapGestureRecognizer
    ) {
        navigateToMusicFullScreenView()
    }
}

// MARK: - UICollectionViewDataSource

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        viewModel?.numberOfItemsInSection(section) ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell: ManageLightViewCell = collectionView.dequeueTypedCell(at: indexPath)
        cell.viewModel = viewModel?.getManageLightViewCellViewModel(at: indexPath)

        return cell
    }
}

// MARK: - HomeViewModelViewControllerDelegate

extension HomeViewController: HomeViewModelViewControllerDelegate {
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        updateHealthStatusViewFor viewContext: ViewContext
    ) {
        switch viewContext {
        case .lights:
            updateLightsViewHealthStatusView()
        case .locks:
            updateLockServiceHealthStatusView()
        case .music:
            updateMusicServiceHealthStatusView()
        }
    }
    
    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        updateSliderValue value: Float?,
        at indexPath: IndexPath
    ) {
        guard
            let item = lightsCollectionView.cellForItem(at: indexPath) as? ManageLightViewCell
        else {
            return
        }
        
        item.viewModel?.updateSliderValue(value)
    }

    func homeViewModelUpdateLabels(_ homeViewModel: HomeViewModelProtocol) {
        setupGreetingLabel()
        setupCurrentTimeLabel()
    }

    func homeViewModelUpdateLockView(_ homeViewModel: HomeViewModelProtocol) {
        updateFrontDoorLockViewSubviews()
    }

    func homeViewModel(
        _ homeViewModel: HomeViewModelProtocol,
        toggleLockViewLoading on: Bool
    ) {
        if on {
            spinnerView.startAnimating()
            lockActionButton.isUserInteractionEnabled = false
            lockActionButton.backgroundColor = .backgroundPrimaryDark.withAlphaComponent(0.75)
        } else {
            spinnerView.stopAnimating()
            lockActionButton.isUserInteractionEnabled = true
            lockActionButton.backgroundColor = .clear
        }
    }
    
    func homeViewModelUpdateMusicLabels(
        _ homeViewModel: HomeViewModelProtocol
    ) {
        updateMusicView()
    }
}
