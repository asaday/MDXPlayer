//
//  DropboxListVC.swift
//  mdxplayer
//
//  Created by asada on 2016/08/27.
//  Copyright  asada. All rights reserved.
//

import UIKit
import SwiftyDropbox

class DropboxListVC: ListVC {

	var client: DropboxClient!
	var downloadedCount: Int = 0
	var downloadingCount: Int = 0
	var remotePath = ""
	var loadingView: UIView?
	var loadingLabel: UILabel?
	var refresh: UIRefreshControl?

	override func viewWillAppear(animated: Bool) {
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
		ref.addTarget(self, action: #selector(doRefresh), forControlEvents: .ValueChanged)
		refresh = ref
	}

	func showRightButton() {
		if Dropbox.authorizedClient == nil && Dropbox.authorizedTeamClient == nil {
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "login", style: .Plain, target: self, action: #selector(tapLogin))
		} else {
			navigationItem.rightBarButtonItem = UIBarButtonItem(title: "logout", style: .Plain, target: self, action: #selector(tapLogout))
		}
	}

	func showLoading(msg: String) {
		if loadingView == nil {

			let v = UIView(frame: view.bounds.resize(-80, 160, .Top).offset(0, 100))
			v.backgroundColor = UIColor(white: 0.2, alpha: 0.8)
			v.layer.cornerRadius = 8
			v.clipsToBounds = true
			view.addSubview(v)

			let lbl = UILabel(frame: v.bounds.resize(-20, -20, .Center))
			lbl.numberOfLines = 0
			lbl.textAlignment = .Center
			lbl.textColor = UIColor.mdxColor
			lbl.font = UIFont(name: "KH-Dot-Kodenmachou-16-Ki", size: 16)
			v.addSubview(lbl)

			tableView.separatorStyle = .None
			loadingView = v
			loadingLabel = lbl
		}
		loadingLabel?.text = "NOW LOADING...\n\n" + msg// \n\n10 / 20"
		view.bringSubviewToFront(loadingView!)
	}

	func hideLoading() {
		loadingView?.removeFromSuperview()
		loadingView = nil
		loadingLabel = nil
	}

	func tapLogin() {
		Dropbox.authorizeFromController(self)
	}

	func tapLogout() {
		Dropbox.unlinkClient()
		showRightButton()
	}

	func loadList() -> Bool {
		list = []
		guard let dat = NSData(contentsOfFile: localPath.appendPath("__list.json")) else { return false }
		guard let json = try? NSJSONSerialization.JSONObjectWithData(dat, options: []) else { return false }
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
		if let dat = try? NSJSONSerialization.dataWithJSONObject(ar, options: []) {
			dat.writeToFile(localPath.appendPath("__list.json"), atomically: true)
		}
	}

	func doRefresh() {
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
		guard let c = Dropbox.authorizedClient else { return }
		client = c
		showRightButton()

		list = []
		downloadedCount = 0
		downloadingCount = 0
		showLoading("LISTING")

		client.files.listFolder(path: remotePath).response { (result, error) in
			guard let result = result else { return }

			for entry in result.entries {
				print(entry)
				if let f = entry as? Files.FolderMetadata {
					self.list.append(Item(title: f.name, file: f.name, isDir: true))
					continue
				}
				if let f = entry as? Files.FileMetadata, lp = f.pathLower {
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

	func doDownload(meta: Files.Metadata) {

		print(meta.pathLower)
		downloadingCount += 1
		let destination: (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
			let dp = Path.caches("__downloadtmp")
			Path.mkdir(dp)
			return NSURL(fileURLWithPath: dp.appendPath(NSUUID().UUIDString))
		}

		client.files.download(path: meta.pathLower!, destination: destination).response { response, error in
			self.downloadedCount += 1
			if let (metadata, url) = response {
				Path.copy(url.path!, dst: self.localPath.appendPath(metadata.name))
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
		tableView.separatorStyle = .SingleLine
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)

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

