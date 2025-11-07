//
//  AppDlegate.swift
//  mdxplayer
//
//  Created by asada on 2016/08/xx.
//  Copyright  asada. All rights reserved.
//

import SwiftyDropbox
import UIKit

extension UIColor {
    static var mdxColor: UIColor {
        return UIColor(red: 140 / 255, green: 146 / 255, blue: 248 / 255, alpha: 1)
    }
}

@main
@MainActor
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DropboxClientsManager.setupWithAppKey("meoje4tyq6ou09p")

        window = UIWindow(frame: UIScreen.main.bounds)

        window?.backgroundColor = .white

        let nav = UINavigationController(rootViewController: RootListVC())

        // iOS 13以降のナビゲーションバー外観設定
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        appearance.backgroundColor = UIColor(white: 43 / 255, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.compactAppearance = appearance
        if #available(iOS 15.0, *) {
            nav.navigationBar.compactScrollEdgeAppearance = appearance
        }

        nav.navigationBar.tintColor = UIColor.mdxColor

        let v = PlayView(frame: nav.view.bounds)
        nav.view.addSubview(v)
        v.isHidden = true

        window?.rootViewController = nav
        window?.makeKeyAndVisible()

        Task { @MainActor in
            v.setClose()  // apply safearea
            v.isHidden = false
        }

        return true
    }

    func application(
        _: UIApplication, open url: URL, options _: [UIApplication.OpenURLOptionsKey: Any]
    ) -> Bool {
        return DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false) {
            guard let authResult = $0 else { return }

            switch authResult {
            case .success(let token):
                print("Success! User is logged into Dropbox with token: \(token)")
            case .cancel:
                print("User canceled OAuth flow.")
            case .error(let error, let description):
                print("Error \(error): \(description ?? "")")
            }
        }
    }
}
