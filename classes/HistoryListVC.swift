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

	static func addHistory(_ path: String, title: String) {
		var histories: [[String: String]] = []
		if path == "_resources_" { return }

		if let dat = try? Data(contentsOf: URL(fileURLWithPath: HistoryListVC.listpath)),
			let json = try? JSONSerialization.jsonObject(with: dat, options: []),
			let ar = json as? [[String: String]] {
				histories = ar
		}

		histories = histories.filter {
			$0["path"] != path }

		histories.insert(["path": path, "title": title], at: 0)
		if histories.count > 64 { histories.removeLast() }

		if let dat = try? JSONSerialization.data(withJSONObject: histories, options: []) {
			Path.mkdir(Path.support)
			try? dat.write(to: URL(fileURLWithPath: HistoryListVC.listpath), options: [.atomic])
		}
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 66
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

		if (indexPath as NSIndexPath).row >= list.count { return cell }

		let item = list[(indexPath as NSIndexPath).row]

		cell.textLabel?.text = item.title
		cell.detailTextLabel?.text = item.file
		cell.accessoryType = .disclosureIndicator

		return cell
	}

	override func reload() {
		list = []

		guard let dat = try? Data(contentsOf: URL(fileURLWithPath: HistoryListVC.listpath)),
			let json = try? JSONSerialization.jsonObject(with: dat, options: []),
			let ar = json as? [[String: String]] else { return }

		for a in ar {
			list.append(Item(title: a["title"] ?? "", file: a["path"] ?? "", isDir: true))
		}
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let item = list[(indexPath as NSIndexPath).row]
		let vc: ListVC = item.file.hasPrefix("_dropbox_") ? DropboxListVC() : ListVC()
		vc.path = item.file
		vc.title = item.title
		navigationController?.pushViewController(vc, animated: true)
		return
	}

}

