

import UIKit
import PushNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    // This is what you would do in a normal app:
    // let pushNotifications = PushNotifications.shared

    var viewController: ViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // This is what you would do in a normal app:
        //self.pushNotifications.start(instanceId: "your_instance_id_here")
        //self.pushNotifications.registerForRemoteNotifications()

        viewController = window?.rootViewController as? ViewController
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        // This is what you would do in a normal app:
        // self.pushNotifications.registerDeviceToken(deviceToken)
        
        // Update the UI and let the user choose when to register the device token with Pusher
        viewController?.myCallbackForApnsSuccessfullyRegistered(deviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // This is what you would do in a normal app:
        // let remoteNotificationType = self.beamsClient.handleNotification(userInfo: userInfo)
        // if remoteNotificationType == .ShouldIgnore {
        //    return // This was an internal-only notification from Pusher.
        // }
        // <handle the incoming message>
    
        // update UI about received message
        viewController?.myCallbackForReceivedMessages(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.noData)
    }

}

