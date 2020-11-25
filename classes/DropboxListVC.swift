//
//  DropboxListVC.swift
//  mdxplayer
//
//  Created by asada on 2016/08/27.
//  Copyright  asada. All rights reserved.
//

import SwiftyDropbox
import UIKit

class DropboxListVC: ListVC {
    var client: DropboxClient!
    var downloadedCount: Int = 0
    var downloadingCount: Int = 0
    var remotePath = ""
    var loadingView: UIView?
    var loadingLabel: UILabel?
    var refresh: UIRefreshControl?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reload()
    }

    override func viewDidLoad() {
        localPath = ListVC.path2local(path)
        remotePath = path.replace("_dropbox_", "")
        Path.mkdir(localPath)
        super.viewDidLoad()
        showRightButton()

        let ref = UIRefreshControl()
        view.addSubview(ref)
        ref.addTarget(self, action: #selector(doRefresh), for: .valueChanged)
        refresh = ref
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loadingView?.frame = view.bounds.resize(-80, 160, .center)
    }

    func showRightButton() {
        if DropboxClientsManager.authorizedClient == nil, DropboxClientsManager.authorizedTeamClient == nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "login", style: .plain, target: self, action: #selector(tapLogin))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "logout", style: .plain, target: self, action: #selector(tapLogout))
        }
    }

    func showLoading(_ msg: String) {
        if loadingView == nil {
            let v = UIView(frame: view.bounds.resize(-80, 160, .center))
            v.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
            v.layer.cornerRadius = 8
            v.clipsToBounds = true
            view.addSubview(v)

            let lbl = UILabel(frame: v.bounds.resize(-20, -20, .center))
            lbl.numberOfLines = 0
            lbl.textAlignment = .center
            lbl.textColor = UIColor.mdxColor
            lbl.font = UIFont(name: "KH-Dot-Kodenmachou-16-Ki", size: 16)
            lbl.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            v.addSubview(lbl)

            tableView.separatorStyle = .none
            loadingView = v
            loadingLabel = lbl
        }
        loadingLabel?.text = "NOW LOADING...\n\n" + msg // \n\n10 / 20"
        view.bringSubviewToFront(loadingView!)
    }

    func hideLoading() {
        loadingView?.removeFromSuperview()
        loadingView = nil
        loadingLabel = nil
    }

    @objc func tapLogin() {
        DropboxClientsManager.authorizeFromController(UIApplication.shared, controller: self, openURL: { (url: URL) -> Void in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        })
    }

    @objc func tapLogout() {
        DropboxClientsManager.unlinkClients()
        showRightButton()
    }

    func loadList() -> Bool {
        list = []
        guard let dat = try? Data(contentsOf: URL(fileURLWithPath: localPath.appendPath("__list.json"))) else { return false }
        guard let json = try? JSONSerialization.jsonObject(with: dat, options: []) else { return false }
        print(json)

        guard let ar = json as? [NSObject] else { return false }
        for a in ar {
            if let item = Item(json: a) { list.append(item) }
        }

        return true
    }

    func saveList() {
        var ar: [NSObject] = []
        for item in list {
            ar.append(item.json)
        }
        if let dat = try? JSONSerialization.data(withJSONObject: ar, options: []) {
            try? dat.write(to: URL(fileURLWithPath: localPath.appendPath("__list.json")), options: [.atomic])
        }
    }

    @objc func doRefresh() {
        Path.remove(localPath.appendPath("__list.json"))
        client = nil
        reload()
    }

    override func reload() {
        if loadList() {
            // load
            tableView.reloadData()
            showRightButton()
            return
        }

        if client != nil { return }
        guard let c = DropboxClientsManager.authorizedClient else { return }
        client = c
        showRightButton()

        list = []
        downloadedCount = 0
        downloadingCount = 0
        showLoading("LISTING")

        _ = client.files.listFolder(path: remotePath).response { result, _ in
            guard let result = result else { return }

            for entry in result.entries {
                print(entry)
                if let f = entry as? Files.FolderMetadata {
                    self.list.append(Item(title: f.name, file: f.name, isDir: true))
                    continue
                }
                if let f = entry as? Files.FileMetadata, let lp = f.pathLower {
                    if lp.hasSuffix(".mdx") || lp.hasSuffix(".pdx") {
                        self.doDownload(f)
                    }
                }
            }

            if self.downloadingCount <= 0 {
                self.didAllDownload()
            }
        }
    }

    func doDownload(_ meta: Files.Metadata) {
        // print(meta.pathLower)
        downloadingCount += 1
        let destination: (URL, HTTPURLResponse) -> URL = { _, _ in
            let dp = Path.caches("__downloadtmp")
            Path.mkdir(dp)
            return URL(fileURLWithPath: dp.appendPath(UUID().uuidString))
        }

        _ = client.files.download(path: meta.pathLower!, destination: destination).response { response, _ in
            self.downloadedCount += 1
            if let (metadata, url) = response {
                Path.copy(url.path, dst: self.localPath.appendPath(metadata.name))
                if meta.pathLower!.hasSuffix(".mdx") {
                    self.list.append(Item(file: meta.name, isDir: false))
                }
            }

            self.showLoading("\(self.downloadedCount) / \(self.downloadingCount)")

            if self.downloadedCount >= self.downloadingCount {
                self.didAllDownload()
            }
        }
    }

    func didAllDownload() {
        hideLoading()
        sortedReload()
        saveList()
        refresh?.endRefreshing()
        client = nil
        tableView.separatorStyle = .singleLine
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = list[indexPath.row]

        if item.isDir {
            let vc = DropboxListVC()
            vc.path = path.appendPath(item.file)
            vc.title = item.title
            navigationController?.pushViewController(vc, animated: true)
            return
        }

        doPlay(indexPath.row)
    }
}
