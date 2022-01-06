import Foundation
import UIKit

protocol ManageLightViewCellViewModelProtocol {
    var titleText: String { get }
    var actionButtonImage: UIImage? { get }
    var sliderValue: Float { get set }
    var sliderMinValue: Float { get }
    var sliderMaxValue: Float { get }
    var delegate: ManageLightViewCellViewModelDelegate? { get set }
    var viewControllerDelegate: ManageLightViewCellViewModelViewControllerDelegate? { get set }
    
    func sliderValueChanged(_ value: Float)
    func actionButtonTapped()
    func updateSliderValue(_ value: Float)
    
}

struct SmartLightData {
    var light: LightType
    var value: Int?
}

protocol ManageLightViewCellViewModelDelegate: AnyObject {
    func manageLightViewCellViewModel(
        _ manageLightViewCellViewModel: ManageLightViewCellViewModelProtocol,
        sliderValueUpdated value: Float,
        forLight light: LightType
    )
}

protocol ManageLightViewCellViewModelViewControllerDelegate: AnyObject {
    func manageLightViewCellViewModelRefreshView(
        _ manageLightViewCellViewModel: ManageLightViewCellViewModelProtocol
    )
}

class ManageLightViewCellViewModel: ManageLightViewCellViewModelProtocol {
    // MARK: - Init

    init(
        smartLightData: SmartLightData,
        delegate: ManageLightViewCellViewModelDelegate? = nil
    ) {
        self.smartLightData = smartLightData
        self.delegate = delegate
        self.sliderValue = Float(smartLightData.value ?? 0)
    }

    // MARK: - Private properties

    private var smartLightData: SmartLightData

    private var oldSliderValue: Float {
        get {
            UserDefaults.standard.object(forKey: oldSliderValueKey) as? Float ??
            sliderMinValue
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: oldSliderValueKey)
        }
    }

    private lazy var oldSliderValueKey = "oldSliderValue_\(smartLightData.light.toString)"

    // MARK: - Public properties

    var titleText: String {
        smartLightData.light.toString
    }

    var actionButtonImage: UIImage? {
        let imageName = sliderValue > sliderMinValue ? "lightOn" : "lightOff"
        return UIImage(named: imageName)
    }

    var sliderValue: Float {
        willSet {
            oldSliderValue = sliderValue
        }
    }

    var sliderMinValue: Float = 0.0

    var sliderMaxValue: Float = 254

    weak var delegate: ManageLightViewCellViewModelDelegate?

    weak var viewControllerDelegate: ManageLightViewCellViewModelViewControllerDelegate?

    // MARK: - Public methods

    func sliderValueChanged(_ value: Float) {
        sliderValue = value
        viewControllerDelegate?.manageLightViewCellViewModelRefreshView(self)
        delegate?.manageLightViewCellViewModel(
            self,
            sliderValueUpdated: sliderValue,
            forLight: smartLightData.light)
    }

    func actionButtonTapped() {
        if sliderValue == sliderMinValue {
            sliderValue = oldSliderValue == sliderMinValue ? 127 : oldSliderValue
        } else {
            sliderValue = sliderMinValue
        }

        viewControllerDelegate?.manageLightViewCellViewModelRefreshView(self)
        delegate?.manageLightViewCellViewModel(
            self,
            sliderValueUpdated: sliderValue,
            forLight: smartLightData.light)
    }
    
    func updateSliderValue(_ value: Float) {
        sliderValue = value
        viewControllerDelegate?.manageLightViewCellViewModelRefreshView(self)
    }
}
