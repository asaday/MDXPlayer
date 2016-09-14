//
//  RootListVC.swift
//  mdxplayer
//
//  Created by asada on 2016/09/02.
//  Copyright asada. All rights reserved.
//

import UIKit

class RootListVC: ListVC {

	override func viewDidLoad() {
		super.viewDidLoad()
		title = "MDX"
		navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "info"), style: .Plain, target: self, action: #selector(tapInfo))
	}

	func tapInfo() {
		navigationController?.pushViewController(InfoVC(), animated: true)
	}

	override func reload() {
		list = [
			Item(title: "Build-in", file: "_resources_", isDir: true),
			Item(title: "Documents", file: "_documents_", isDir: true),
			Item(title: "Dropbox", file: "_dropbox_", isDir: true),
			Item(title: "History", file: "_history_", isDir: true),
			Item(title: "Random", file: "_random_", isDir: true),
		]
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 66
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let item = list[indexPath.row]

		if item.file == "_random_" {
			doRandomPlay([ListVC.path2local("_documents_"), ListVC.path2local("_dropbox_")])
			return
		}

		var vc: ListVC!
		if item.file == "_dropbox_" { vc = DropboxListVC() }
		else if item.file == "_history_" { vc = HistoryListVC() }
		else { vc = ListVC() }

		vc.path = item.file
		vc.title = item.title
		navigationController?.pushViewController(vc, animated: true)
	}

	func listupmdx(path: String) -> [String] {
		var lists: [String] = []
		let ar = Path.files(path)
		for p in ar {
			let s = path.appendPath(p)
			if Path.isDir(s) { lists.appendContentsOf(listupmdx(s)) }
			if !p.lowercaseString.hasSuffix(".mdx") { continue }
			lists.append(s)
		}
		return lists
	}

	func doRandomPlay(paths: [String]) {
		var lists: [String] = []
		for path in paths {
			lists.appendContentsOf(listupmdx(path))
		}

		lists.sortInPlace { _, _ in arc4random() % 2 == 0 }
		while lists.count > 512 { lists.removeLast() }

		Player.sharedInstance().playFiles(lists, index: 0)
	}

}

