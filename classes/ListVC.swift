//
//  ListVC.swift
//  mdxplayer
//
//  Created by asada on 2016/08/13.
//  Copyright asada. All rights reserved.
//

import UIKit

class ListCell: UITableViewCell {

	required init?(coder _: NSCoder) {
		fatalError() }

	override init(style _: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
		backgroundColor = UIColor(white: 23 / 255, alpha: 1)

		textLabel?.font = UIFont(name: "KH-Dot-Kodenmachou-16-Ki", size: 16) // UIFont.systemFontOfSize(16)
		textLabel?.font = .systemFont(ofSize: 16)
		textLabel?.textColor = .white
		textLabel?.numberOfLines = 2
		detailTextLabel?.textColor = UIColor(red: 174 / 255.0, green: 189 / 255.0, blue: 203 / 255.0, alpha: 1)
		detailTextLabel?.font = .systemFont(ofSize: 12)

		let sv = UIView()
		sv.backgroundColor = UIColor(white: 1, alpha: 0.2)
		selectedBackgroundView = sv
	}
}

struct Item {
	var title: String?
	var file = ""
	var isDir = false

	var json: NSObject {
		var r: [String: NSObject] = [:]
		r["file"] = file as NSObject
		r["isDir"] = isDir as NSObject
		r["title"] = (title ?? "") as NSObject
		return r as NSObject
	}

	init() {}

	init(file: String, isDir: Bool) {
		self.file = file
		self.isDir = isDir
		if isDir { title = file }
	}

	init(title: String, file: String, isDir: Bool) {
		self.title = title
		self.file = file
		self.isDir = isDir
	}

	init?(json: NSObject) {
		guard let r = json as? [String: NSObject] else { return nil }
		guard let f = r["file"] as? String else { return nil }
		file = f
		isDir = r["isDir"] as? Bool ?? false
		title = r["title"] as? String
		if title == "" { title = nil }
	}
}

class ListVC: UITableViewController {

	var path = ""
	var list: [Item] = []

	var localPath = ""

	static func path2local(_ p: String) -> String {

		let reps: [String: String] = [
			"_documents_": Path.documents,
			"_resources_": Path.resource("buildin"),
			"_dropbox_": Path.caches("_dropbox_"),
		]

		for (k, v) in reps {
			if p.hasPrefix(k) { return p.replace(k, v) }
		}
		return p
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		localPath = ListVC.path2local(path)
		print(localPath)
		print(path)
		tableView.rowHeight = 66
		tableView.separatorColor = UIColor(white: 61 / 255, alpha: 1)
		tableView.backgroundColor = UIColor(white: 13 / 255, alpha: 1)
		tableView.register(ListCell.self, forCellReuseIdentifier: "cell")
		tableView.contentInset.bottom = 66
		reload()
	}

	func reload() {
		list.removeAll()
		let ar = Path.files(localPath)
		for s in ar {
			if s.hasPrefix(".") { continue }
			let isdir = Path.isDir(localPath.appendPath(s))
			if !isdir && !s.lowercased().hasSuffix(".mdx") { continue }
			list.append(Item(file: s, isDir: isdir))
		}
		sortedReload()

		if list.count == 0 && path == "_documents_" {
			showInfo("Copy files with iTunes app from PC/mac/X68k")
		}
	}

	func sortedReload() {
		list.sort { (a, b) -> Bool in
			if a.isDir != b.isDir { return a.isDir }
			return a.file.lowercased() < b.file.lowercased()
		}
		tableView.reloadData()
	}

	override func numberOfSections(in _: UITableView) -> Int {
		return 1
	}

	override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
		return list.count
	}

	override func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.row >= list.count { return 44 }
		let item = list[indexPath.row]
		return item.isDir ? 44 : 66
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

		if indexPath.row >= list.count { return cell }

		let item = list[indexPath.row]

		if item.isDir {
			cell.textLabel?.text = item.title
			cell.detailTextLabel?.text = ""
			cell.accessoryType = .disclosureIndicator
			return cell
		}

		cell.textLabel?.text = item.file
		cell.accessoryType = .none

		cell.detailTextLabel?.text = item.file

		if let n = item.title {
			cell.textLabel?.text = n
			return cell
		}

		Dispatch.background {
			let n = Player.title(forMDXFile: self.localPath.appendPath(item.file))
			if indexPath.row >= self.list.count { return }
			self.list[indexPath.row].title = n
			Dispatch.main {
				guard let mc = tableView.cellForRow(at: indexPath) else { return }
				mc.textLabel?.text = n
			}
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)

		if indexPath.row >= list.count { return }
		let item = list[indexPath.row]

		if item.isDir {
			let vc = ListVC()
			vc.path = path.appendPath(item.file)
			vc.title = item.title
			navigationController?.pushViewController(vc, animated: true)
			return
		}

		doPlay(indexPath.row)
	}

	func doPlay(_ row: Int) {
		if row >= list.count { return }
		let item = list[row]
		var playlist: [String] = []
		var selected: Int = 0
		for c in list {
			if c.isDir { continue }
			if c.file == item.file { selected = playlist.count }
			playlist.append(localPath.appendPath(c.file))
		}

		HistoryListVC.addHistory(path, title: title ?? "")
		Player.sharedInstance().playFiles(playlist, index: selected)
	}
}
