//
//  NotificationManager.swift
//  Pipelines
//
//  Created by Bas van Kuijck on 29/09/2017.
//  Copyright © 2017 E-sites. All rights reserved.
//

import Foundation
import NotificationCenter
import Macaw
import SwiftyUserDefaults
import Apollo

extension DefaultsKeys {
    fileprivate static let deliveredNotifications = DefaultsKey<[String]>("deliveredNotifications")
}

class NotificationManager {
    static let `default` = NotificationManager()

    private init() {

    }

    fileprivate func _notificationIdentifier(`for` node: LatestBuildsQuery.Data.Viewer.User.Build.Edge.Node) -> String {
        var buildState = BuildState(from: node.state)
        if buildState == .scheduled || buildState == .empty {
            buildState = .running
        }
        return node.id + buildState.rawValue
    }

    func hasNotificationBeenTriggered(`for` node: LatestBuildsQuery.Data.Viewer.User.Build.Edge.Node) -> Bool {
        let identifier = _notificationIdentifier(for: node)
        return Defaults[.deliveredNotifications].contains(identifier)
    }

    func triggerLocalNotification(`for` node: LatestBuildsQuery.Data.Viewer.User.Build.Edge.Node) {
        if hasNotificationBeenTriggered(for: node) {
            return
        }
        guard let pipeline = node.pipeline?.name else {
            return
        }
        let identifier = _notificationIdentifier(for: node)
        Defaults[.deliveredNotifications].append(identifier)

        let notification = NSUserNotification()

        var svgImage: String?
        switch BuildState(from: node.state) {
        case .passed:
            notification.title = "Build is passed!"
            svgImage = "passed"
        case .failed:
            notification.title = "Build is failed!"
            svgImage = "failed"
        default:
            notification.title = "New build"
        }

        if let icon = svgImage {
            let frame = NSRect(x: 0, y: 0, width: 128, height: 128)
            let v = SVGView(frame: frame)
            v.contentMode = .scaleAspectFit
            v.backgroundColor = MColor.clear
            v.fileName = icon
            notification.contentImage = v.image()
        }

        notification.subtitle = pipeline.emojiRendered
        notification.informativeText = node.message.emojiRendered
        NSUserNotificationCenter.default.deliver(notification)
    }
}
