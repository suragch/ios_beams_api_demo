# iOS Beams client API Demo

Demonstration of the Pusher Beams client SDK for iOS

This is a supplemental project for the article [Pusher Beams client API demo for iOS](TODO).

## Setup

To set up this demo app, perform the following tasks:

1. Clone the GitHub repo
2. [Create a Beams instance and configure APNs](https://pusher.com/docs/beams/getting-started/ios/configure-apns). You can follow the quick start guide. After you have entered your APNs signing key and team ID, you can exit the quick start wizard. Go to your [Beams dashboard](https://dash.pusher.com/beams), open your new instance, and go to the **Credentials** tab. You will find your Instance ID and Secret Key there. 
3. Using Xcode, in the cloned repo target settings, in the **General** section, update your bundle ID so that it is unique and make sure that your **Team** is set to your developer account. In the **Capabilities** section, make sure that **Push Notifications** is on and that **Background Modes > Remote notifications** is checked.
4. In the cloned repo’s `ViewController.swift` file, set the `instanceId` at the top to your Pusher Beams Instance ID.
5. Run the app on a real device.
