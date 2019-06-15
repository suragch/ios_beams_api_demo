
import UIKit
import PushNotifications

class ViewController: UIViewController, InterestsChangedDelegate {

    
    
    @IBOutlet weak var resultsView: UIView!
    @IBOutlet weak var resultsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // listen to InterestsChangedDelegate
        // see interestsSetOnDeviceDidChange
        beamsClient.delegate = self
        
        // in a normal app, if the user is still logged in then you
        // should setUserId when the app launches. You could do that here.
        
        // results view
        resultsLabel.isHidden = true
        resultsView.isHidden = true
        resultsView.layer.cornerRadius = 5;
        resultsView.layer.masksToBounds = true;
    }
    
    // SDK
    
    let beamsClient = PushNotifications.shared
    var deviceToken: Data? = nil
    
    
    @IBAction func onStartTap(_ sender: UIButton) {
        beamsClient.start(instanceId: "afc7aaf1-3018-4709-adf8-e779bcd48551")
        showResultsInLabel(message: "SDK started")
    }
    
    @IBAction func onStopTap(_ sender: UIButton) {
        beamsClient.stop() {
            self.showResultsInLabel(message: "SDK stopped")
        }
    }
    
    @IBAction func onRegisterWithAppleTap(_ sender: UIButton) {
        beamsClient.registerForRemoteNotifications()
        
    }
    
    func myCallbackForApnsSuccessfullyRegistered(deviceToken: Data) {
        self.deviceToken = deviceToken
        showResultsInLabel(message: "app successfully registered with APNs")
    }
    
    @IBAction func onRegisterWithPusherTap(_ sender: UIButton) {
        if let token = deviceToken {
            beamsClient.registerDeviceToken(token);
            showResultsInLabel(message: "registered device token")
        } else {
            showResultsInLabel(message: "Failed. You need to register with Apple")
        }
    }
    
    // Device Interests
    
    @IBAction func onGetInterestsTap(_ sender: UIButton) {
        if let interests = beamsClient.getDeviceInterests() {
            showResultsInLabel(message: "Interests: \(interests)")
        }
    }
    
    @IBAction func onSetInterestsTap(_ sender: UIButton) {
        showMultiChoiceAlertController()
    }
    
    func onReturnFromUserSelectedSetInterests(interests: [String]) {
        do {
            try beamsClient.setDeviceInterests(interests: interests)
            showResultsInLabel(message: "Set Interests: \(interests)")
        } catch is MultipleInvalidInterestsError {
            print("There are invalid interests name(s)")
        } catch {
            print("error")
        }
    }
    
    @IBAction func onClearInterestsTap(_ sender: UIButton) {
        do {
            try beamsClient.clearDeviceInterests()
            showResultsInLabel(message: "Cleared interests")
        } catch {
            print("error")
        }
    }
    
    @IBAction func onAddInterestsTap(_ sender: UIButton) {
        showSingleChoiceActionSheet(actionType: .addInterest)
    }
    
    func onReturnFromUserSelectedAddInterest(interest: String) {
        do {
            try beamsClient.addDeviceInterest(interest: interest)
            showResultsInLabel(message: "Added Interest: \(interest)")
        } catch is InvalidInterestError {
            print("Invalid interest name")
        } catch {
            print("error")
        }
    }
    
    @IBAction func onRemoveInterestsTap(_ sender: UIButton) {
        showSingleChoiceActionSheet(actionType: .removeInterest)
    }
    
    func onReturnFromUserSelectedRemoveInterest(interest: String) {
        do {
            try beamsClient.removeDeviceInterest(interest: interest)
            showResultsInLabel(message: "Removed Interest: \(interest)")
        } catch is InvalidInterestError {
            print("Invalid interest name")
        } catch {
            print("error")
        }
    }
    
    // User
    
    @IBAction func onSetUserIdTap(_ sender: UIButton) {
        
        let userId = "Mary"
        let password = "mypassword"
        let data = "\(userId):\(password)".data(using: String.Encoding.utf8)!
        let base64 = data.base64EncodedString()
        
        let serverIP = "192.168.1.3"
        let tokenProvider = BeamsTokenProvider(authURL: "http://\(serverIP):8888/token") { () -> AuthData in
            let headers = ["Authorization": "Basic \(base64)"]
            let queryParams: [String: String] = [:]
            return AuthData(headers: headers, queryParams: queryParams)
        }
        
        self.beamsClient.setUserId(userId, tokenProvider: tokenProvider, completion: { error in
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            
            self.showResultsInLabel(message: "Successfully authenticated with Pusher Beams")
        })
    }
    
    @IBAction func onClearAllStateTap(_ sender: UIButton) {
        beamsClient.clearAllState {
            self.showResultsInLabel(message: "state cleared")
        }
    }
    
    // Events
    
    var timesInterestsChanged = 0
    @IBOutlet weak var interestsChangedNumber: UILabel!
    
    func interestsSetOnDeviceDidChange(interests: [String]) {
        timesInterestsChanged += 1
        interestsChangedNumber.text = String(timesInterestsChanged)
    }
    
    var timesMessagesReceived = 0
    @IBOutlet weak var messagesReceivedLabel: UILabel!
    
    func myCallbackForReceivedMessages(userInfo: [AnyHashable: Any]) {
        timesMessagesReceived += 1
        messagesReceivedLabel.text = String(timesMessagesReceived)
        
        let message = extractUserInfo(userInfo: userInfo)
        showResultsInLabel(message: "New message: \(message.title), \(message.body)")
    }
    
    // thanks: https://stackoverflow.com/a/51778032
    func extractUserInfo(userInfo: [AnyHashable : Any]) -> (title: String, body: String) {
        var info = (title: "", body: "")
        guard let aps = userInfo["aps"] as? [String: Any] else { return info }
        guard let alert = aps["alert"] as? [String: Any] else { return info }
        let title = alert["title"] as? String ?? ""
        let body = alert["body"] as? String ?? ""
        info = (title: title, body: body)
        return info
    }
    
    // Helper methods
    
    func showSingleChoiceActionSheet(actionType: ActionType) {
        
        var title = ""
        if (actionType == ActionType.addInterest) {
            title = "Select interest to add"
        } else {
            title = "Select interest to remove"
        }
        
        // Create the action sheet
        let myActionSheet = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let appleAction = UIAlertAction(title: "apple", style: UIAlertAction.Style.default) { (action) in
            self.onSingleChoiceResult(chosenInterest: "apple", actionType: actionType)
        }
        let pearAction = UIAlertAction(title: "pear", style: UIAlertAction.Style.default) { (action) in
            self.onSingleChoiceResult(chosenInterest: "pear", actionType: actionType)
        }
        let orangeAction = UIAlertAction(title: "orange", style: UIAlertAction.Style.default) { (action) in
            self.onSingleChoiceResult(chosenInterest: "orange", actionType: actionType)
        }
        let bananaAction = UIAlertAction(title: "banana", style: UIAlertAction.Style.default) { (action) in
            self.onSingleChoiceResult(chosenInterest: "banana", actionType: actionType)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (action) in
        }
        
        // add action buttons to action sheet
        myActionSheet.addAction(appleAction)
        myActionSheet.addAction(pearAction)
        myActionSheet.addAction(orangeAction)
        myActionSheet.addAction(bananaAction)
        myActionSheet.addAction(cancelAction)
        
        // present the action sheet
        self.present(myActionSheet, animated: true, completion: nil)
    }
    
    func onSingleChoiceResult(chosenInterest: String?, actionType: ActionType) {
        guard let choice = chosenInterest else {
            return
        }
        if (actionType == ActionType.addInterest) {
            self.onReturnFromUserSelectedAddInterest(interest: choice)
        } else {
            self.onReturnFromUserSelectedRemoveInterest(interest: choice)
        }
    }
    
    func showMultiChoiceAlertController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let myAlert = storyboard.instantiateViewController(withIdentifier: "alert") as! MultiChoiceAlertViewController
        
        myAlert.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        myAlert.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        myAlert.onCompletion = { interests in
            self.onReturnFromUserSelectedSetInterests(interests: interests)
        }
        self.present(myAlert, animated: true, completion: nil)
    }
    
    func showResultsInLabel(message: String) {
        resultsLabel.isHidden = false
        resultsView.isHidden = false
        resultsLabel.text = message
        print(message)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.resultsLabel.text = ""
            self.resultsLabel.isHidden = true
            self.resultsView.isHidden = true
        }
    }

}




enum ActionType {
    case addInterest
    case removeInterest
}
