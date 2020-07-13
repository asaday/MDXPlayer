//
//  AppDlegate.swift
//  mdxplayer
//
//  Created by asada on 2016/08/xx.
//  Copyright  asada. All rights reserved.
//

import UIKit
import SwiftyDropbox

extension UIColor {
	static var mdxColor: UIColor { return UIColor(red: 140 / 255, green: 146 / 255, blue: 248 / 255, alpha: 1) }
}

import SwiftyDropbox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		DropboxClientsManager.setupWithAppKey("meoje4tyq6ou09p")

		window = UIWindow(frame: UIScreen.main.bounds)

		window?.backgroundColor = .white

		let nav = UINavigationController(rootViewController: RootListVC())

		nav.navigationBar.barStyle = .blackTranslucent
		nav.navigationBar.tintColor = UIColor.mdxColor
		nav.navigationBar.backgroundColor = UIColor(white: 43 / 255, alpha: 1)

		let v = PlayView(frame: nav.view.bounds)
		nav.view.addSubview(v)
		v.isHidden = true

		window?.rootViewController = nav
		window?.makeKeyAndVisible()

		Dispatch.main {
			v.setClose() // apply safearea
			v.isHidden = false
		}

		return true
	}

    func application(_: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {

		if let authResult = DropboxClientsManager.handleRedirectURL(url) {
			switch authResult {
			case let .success(token):
				print("Success! User is logged into Dropbox with token: \(token)")
			case .cancel:
				print("User canceled OAuth flow.")
			case let .error(error, description):
				print("Error \(error): \(description)")
			}
		}

		return false
	}
}
