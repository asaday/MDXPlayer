//
//  HistoryListVC.swift
//  mdxplayer
//
//  Created by asada on 2016/08/27.
//  Copyright asada. All rights reserved.
//

import UIKit

class HistoryListVC: ListVC {

	static let listpath = Path.support("history.json")

	static func addHistory(path: String, title: String) {
		var histories: [[String: String]] = []
		if path == "_resources_" { return }

		if let dat = NSData(contentsOfFile: HistoryListVC.listpath),
			let json = try? NSJSONSerialization.JSONObjectWithData(dat, options: []),
			let ar = json as? [[String: String]] {
				histories = ar
		}

		histories = histories.filter {
			$0["path"] != path }

		histories.insert(["path": path, "title": title], atIndex: 0)
		if histories.count > 64 { histories.removeLast() }

		if let dat = try? NSJSONSerialization.dataWithJSONObject(histories, options: []) {
			Path.mkdir(Path.support)
			dat.writeToFile(HistoryListVC.listpath, atomically: true)
		}
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 66
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)

		if indexPath.row >= list.count { return cell }

		let item = list[indexPath.row]

		cell.textLabel?.text = item.title
		cell.detailTextLabel?.text = item.file
		cell.accessoryType = .DisclosureIndicator

		return cell
	}

	override func reload() {
		list = []

		guard let dat = NSData(contentsOfFile: HistoryListVC.listpath),
			let json = try? NSJSONSerialization.JSONObjectWithData(dat, options: []),
			let ar = json as? [[String: String]] else { return }

		for a in ar {
			list.append(Item(title: a["title"] ?? "", file: a["path"] ?? "", isDir: true))
		}
	}

	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let item = list[indexPath.row]
		let vc: ListVC = item.file.hasPrefix("_dropbox_") ? DropboxListVC() : ListVC()
		vc.path = item.file
		vc.title = item.title
		navigationController?.pushViewController(vc, animated: true)
		return
	}

}

