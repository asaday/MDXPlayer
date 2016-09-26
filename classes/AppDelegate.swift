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

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		DropboxClientsManager.setupWithAppKey("meoje4tyq6ou09p")

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.backgroundColor = UIColor.white

		let nav = UINavigationController(rootViewController: RootListVC())

		nav.navigationBar.barStyle = .blackTranslucent
		nav.navigationBar.tintColor = UIColor.mdxColor
		nav.navigationBar.backgroundColor = UIColor(white: 43 / 255, alpha: 1)

		let v = PlayView(frame: nav.view.bounds.resize(0, 66, .top))
		v.frame = nav.view.bounds.resize(0, 66, .bottom)
		v.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
		nav.view.addSubview(v)

		window?.rootViewController = nav
		window?.makeKeyAndVisible()

		return true
	}

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey: Any]) -> Bool {

		if let authResult = DropboxClientsManager.handleRedirectURL(url) {
			switch authResult {
			case .success(let token):
				print("Success! User is logged into Dropbox with token: \(token)")
			case .cancel:
				print("User canceld OAuth flow.")
			case .error(let error, let description):
				print("Error \(error): \(description)")
			}
		}

		return false
	}

}

