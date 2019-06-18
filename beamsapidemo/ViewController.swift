
import UIKit
import PushNotifications

class ViewController: UIViewController, InterestsChangedDelegate {
    
    // get a reference to the PushNotifications instance
    let beamsClient = PushNotifications.shared

    // replace this with your own Pusher Beams Instance ID
    // You can get this ID from the Beams dashboard: https://dash.pusher.com/beams
    // Example:
    // let instanceId = "111111111-22222-3333-aaaa-66666666666"
    let instanceId = MyConfig.instanceId
    
    var deviceToken: Data? = nil
    
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
    
    @IBAction func onStartTap(_ sender: UIButton) {
        beamsClient.start(instanceId: instanceId)
        showResultsInLabel(message: "SDK started")
    }
    
    @IBAction func onStopTap(_ sender: UIButton) {
        beamsClient.stop() {
            self.showResultsInLabel(message: "SDK stopped")
        }
    }
    
    @IBAction func onRegisterWithAppleTap(_ sender: UIButton) {
        // this method tells APNs that we want to be able to receive
        // alert, badge, and sound notifications
        beamsClient.registerForRemoteNotifications()
        
        // alternatively, you could register a request for different kinds
        // of notifications. This one does alert and sound but not badge:
        // beamsClient.registerForRemoteNotifications(options: [.alert, .sound])
    }
    
    // I'm clalling this from AppDelegate.swift
    func myCallbackForApnsSuccessfullyRegistered(deviceToken: Data) {
        self.deviceToken = deviceToken
        showResultsInLabel(message: "app successfully registered with APNs")
    }
    
    @IBAction func onRegisterWithPusherTap(_ sender: UIButton) {
        if let token = deviceToken {
            beamsClient.registerDeviceToken(token);
            showResultsInLabel(message: "registering device token")
        } else {
            showResultsInLabel(message: "Failed. You need to register with Apple")
        }
    }
    
    // Device Interests
    
    @IBAction func onGetInterestsTap(_ sender: UIButton) {
        guard let interests = beamsClient.getDeviceInterests() else { return }
        showResultsInLabel(message: "Interests: \(interests)")
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
        try? beamsClient.clearDeviceInterests()
        showResultsInLabel(message: "Cleared interests")
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
        
        // basic authentication credentials
        let userId = "Mary"
        let password = "mypassword"
        let data = "\(userId):\(password)".data(using: String.Encoding.utf8)!
        let base64 = data.base64EncodedString()
        
        // Token Provider
        let serverIP = "192.168.1.3" // change this to your server IP
        let tokenProvider = BeamsTokenProvider(authURL: "http://\(serverIP):8888/token") { () -> AuthData in
            let headers = ["Authorization": "Basic \(base64)"]
            let queryParams: [String: String] = [:]
            return AuthData(headers: headers, queryParams: queryParams)
        }
        
        // Get the Beams token and send it to Pusher
        self.beamsClient.setUserId(
            userId,
            tokenProvider: tokenProvider,
            completion: { error in
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            self.showResultsInLabel(message: "Successfully authenticated with Beams")
        })
    }
    
    @IBAction func onClearAllStateTap(_ sender: UIButton) {
        beamsClient.clearAllState {
            self.showResultsInLabel(message: "state cleared")
        }
    }
    
    // Events
    
    var interestsChangedCount = 0
    @IBOutlet weak var interestsChangedNumber: UILabel!
    func interestsSetOnDeviceDidChange(interests: [String]) {
        interestsChangedCount += 1
        interestsChangedNumber.text = String(interestsChangedCount)
    }
    
    var messagesReceivedCount = 0
    @IBOutlet weak var messagesReceivedLabel: UILabel!
    func myCallbackForReceivedMessages(userInfo: [AnyHashable: Any]) {
        messagesReceivedCount += 1
        messagesReceivedLabel.text = String(messagesReceivedCount)
        
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
        
        myActionSheet.addAction(appleAction)
        myActionSheet.addAction(pearAction)
        myActionSheet.addAction(orangeAction)
        myActionSheet.addAction(bananaAction)
        myActionSheet.addAction(cancelAction)
        
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
