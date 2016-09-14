//
//  AppDlegate.swift
//  mdxplayer
//
//  Created by asada on 2016/08/xx.
//  Copyright  asada. All rights reserved.
//

import UIKit

extension UIColor {
	static var mdxColor: UIColor { return UIColor(red: 140 / 255, green: 146 / 255, blue: 248 / 255, alpha: 1) }
}

import SwiftyDropbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

		Dropbox.setupWithAppKey("meoje4tyq6ou09p")

		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window?.backgroundColor = UIColor.whiteColor()

		let nav = UINavigationController(rootViewController: RootListVC())

		nav.navigationBar.barStyle = .BlackTranslucent
		nav.navigationBar.tintColor = UIColor.mdxColor
		nav.navigationBar.backgroundColor = UIColor(white: 43 / 255, alpha: 1)

		let v = PlayView(frame: nav.view.bounds.resize(0, 66, .Top))
		v.frame = nav.view.bounds.resize(0, 66, .Bottom)
		v.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
		nav.view.addSubview(v)

		window?.rootViewController = nav
		window?.makeKeyAndVisible()

		return true
	}

	func applicationDidEnterBackground(application: UIApplication) {
		UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
		self.becomeFirstResponder()
	}

	func applicationWillEnterForeground(application: UIApplication) {
		UIApplication.sharedApplication().endReceivingRemoteControlEvents()
	}

	override func canBecomeFirstResponder() -> Bool {
		return true
	}

	override func remoteControlReceivedWithEvent(event: UIEvent?) {
		if event?.type != .RemoteControl { return }

		postNotification("REMOTE", object: event)
	}

	func application(app: UIApplication, openURL url: NSURL, options: [String: AnyObject]) -> Bool {

		if let authResult = Dropbox.handleRedirectURL(url) {
			switch authResult {
			case .Success(let token):
				print("Success! User is logged into Dropbox with token: \(token)")
			case .Cancel:
				print("User canceld OAuth flow.")
			case .Error(let error, let description):
				print("Error \(error): \(description)")
			}
		}

		return false
	}

}

