//
//  StatusItem.swift
//  Pipelines
//
//  Created by Bas van Kuijck on 28/09/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation
import Cocoa
import Apollo
import NotificationCenter
import SwiftyUserDefaults

class StatusItemManager {
    private(set) var statusItem: NSStatusItem!
    private var _statusIcons: [StatusIconView] = []
   

    init() {
    }

    private func _addNewStatusIconView() {
        let x = CGFloat(_statusIcons.count) * 20
        let frame = NSRect(x: x, y: 0, width: 20, height: 20)

        let iconView = StatusIconView(frame: frame)
        _statusIcons.append(iconView)

        statusItem.button?.addSubview(iconView)

        statusItem.length = CGFloat(_statusIcons.count * 20) + 2
    }

    func setup(with statusItem: NSStatusItem) {
        if self.statusItem != nil {
            fatalError("Already set up!")
        }
        self.statusItem = statusItem
        guard let button = statusItem.button else {
            return
        }

        button.target = self
        button.action = #selector(_tapStatusButton)
        
        statusItem.length = NSStatusItem.squareLength
    }

    var nodes: [LatestBuildsQuery.Data.Viewer.User.Build.Edge.Node] = [] {
        didSet {
            _updateNodes()
        }
    }

    private func _updateNodes() {
        for (index, node) in nodes.enumerated() {
            if index == _statusIcons.count {
                _addNewStatusIconView()
            }
            let iconView = _statusIcons[index]
            iconView.state = BuildState(from: node.state)
            if index == 0 {
                triggerLocalNotification(for: node)
            }
        }
    }

    @objc
    private func _tapStatusButton() {
        let url = URL(string: "https://buildkite.com/builds")!
        NSWorkspace.shared.open(url)
    }
}

extension DefaultsKeys {
    fileprivate static let deliveredNotifications = DefaultsKey<[String]>("deliveredNotifications")
}

extension StatusItemManager {
    func triggerLocalNotification(`for` node: LatestBuildsQuery.Data.Viewer.User.Build.Edge.Node) {
        if Defaults[.deliveredNotifications].contains(node.id) {
            return
        }

        guard let pipeline = node.pipeline?.name else {
            return
        }
        Defaults[.deliveredNotifications].append(node.id)

        let notification = NSUserNotification()
        notification.title = "New build"
        notification.subtitle = pipeline.emojiRendered
        notification.informativeText = node.message.emojiRendered
        NSUserNotificationCenter.default.deliver(notification)
    }
}
