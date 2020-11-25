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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(tapInfo))
    }

    @objc func tapInfo() {
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

    override func tableView(_: UITableView, heightForRowAt _: IndexPath) -> CGFloat {
        return 66
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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

    func listupmdx(_ path: String) -> [String] {
        var lists: [String] = []
        let ar = Path.files(path)
        for p in ar {
            let s = path.appendPath(p)
            if Path.isDir(s) { lists.append(contentsOf: listupmdx(s)) }
            if !p.lowercased().hasSuffix(".mdx") { continue }
            lists.append(s)
        }
        return lists
    }

    func doRandomPlay(_ paths: [String]) {
        var lists: [String] = []
        for path in paths {
            lists.append(contentsOf: listupmdx(path))
        }

        lists.sort { _, _ in arc4random() % 2 == 0 }
        while lists.count > 512 { lists.removeLast() }

        Player.sharedInstance().playFiles(lists, index: 0)
    }
}
