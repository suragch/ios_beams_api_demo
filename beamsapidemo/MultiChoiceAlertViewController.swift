
import UIKit

class MultiChoiceAlertViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        alertViewContainer.layer.cornerRadius = 5
        alertViewContainer.layer.masksToBounds = true
    }
    
    var onCompletion : (([String]) -> Void)?

    @IBOutlet weak var alertViewContainer: UIView!
    @IBOutlet weak var appleSwitch: UISwitch!
    @IBOutlet weak var pearSwitch: UISwitch!
    @IBOutlet weak var orangeSwitch: UISwitch!
    @IBOutlet weak var bananaSwitch: UISwitch!
    
    @IBAction func onCancelTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onOkTapped(_ sender: UIButton) {
        var interests: [String] = []
        if appleSwitch.isOn {
            interests.append("apple")
        }
        if pearSwitch.isOn {
            interests.append("pear")
        }
        if orangeSwitch.isOn {
            interests.append("orange")
        }
        if bananaSwitch.isOn {
            interests.append("banana")
        }
        
        onCompletion?(interests)
        self.dismiss(animated: true, completion: nil)
    }
    
}
