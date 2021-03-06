import UIKit
import TactileSlider

class ManageLightViewCell: UICollectionViewCell {
    // MARK: - Outlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var slider: TactileSlider!
    @IBOutlet weak var sliderImageView: UIImageView!
    @IBOutlet weak var actionButtonImageView: UIImageView!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: - Lifecycle methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    var viewModel: ManageLightViewCellViewModelProtocol? {
        didSet {
            viewModel?.viewControllerDelegate = self
            setup()
        }
    }

    // MARK: - Private methods

    private func setup() {
        setupTitleLabel()
        setupActionButton()
        setupSlider()
    }
    
    private func setupTitleLabel() {
        titleLabel.text = viewModel?.titleText
        titleLabel.textColor = .offWhite
    }

    private func setupActionButton() {
        actionButtonImageView.image = viewModel?.actionButtonImage
        actionButton.isUserInteractionEnabled = viewModel?.controlsEnabled ?? false
    }

    private func setupSlider() {
        slider.minimum = viewModel?.sliderMinValue ?? 0
        slider.maximum = viewModel?.sliderMaxValue ?? 254
        slider.setValue(viewModel?.sliderValue ?? 0, animated: false)
        slider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        slider.isUserInteractionEnabled = viewModel?.controlsEnabled ?? false
        setupSliderImageView()
    }
    
    private func setupSliderImageView() {
        guard let sliderImage = viewModel?.sliderImage else {
            sliderImageView.isHidden = true
            return
        }
        
        sliderImageView.image = sliderImage
        sliderImageView.isHidden = false
    }

    private func refreshView() {
        actionButtonImageView.image = viewModel?.actionButtonImage
        slider.setValue(viewModel?.sliderValue ?? 0, animated: true)
        actionButton.isUserInteractionEnabled = viewModel?.controlsEnabled ?? false
        slider.isUserInteractionEnabled = viewModel?.controlsEnabled ?? false
        setupSliderImageView()
    }

    // MARK: - Callbacks

    @objc func sliderValueChanged(sender: AnyObject) {
        viewModel?.sliderValueChanged(slider.value)
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
        viewModel?.actionButtonTapped()
    }
}

// MARK: - ManageLightViewCellViewModelViewControllerDelegate

extension ManageLightViewCell: ManageLightViewCellViewModelViewControllerDelegate {
    func manageLightViewCellViewModelRefreshView(
        _ manageLightViewCellViewModel: ManageLightViewCellViewModelProtocol
    ) {
        refreshView()
    }
}
