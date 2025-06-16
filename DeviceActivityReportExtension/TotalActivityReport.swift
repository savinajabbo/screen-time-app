//
//  TotalActivityReport.swift
//  DeviceActivityReportExtension
//
//  Created by Savina Jabbo on 6/10/25.
//

import DeviceActivity
import SwiftUI
import OSLog

extension DeviceActivityReport.Context {
    static let total = Self("TotalActivity")
}

struct TotalActivityReport: DeviceActivityReportScene {

    let context: DeviceActivityReport.Context = .total
    typealias Configuration = String
    let content: (String) -> TotalActivityView

    func makeConfiguration(
        representing data: DeviceActivityResults<DeviceActivityData>
    ) async -> String {

        let log = Logger(subsystem: "TotalActivity", category: "Report")
        log.debug("⚙️ Generating TotalActivityReport")

        // formatter for minutes like “12 m”
        let minutesFmt: (TimeInterval) -> String = { secs in
            "\(Int(secs/60))"
        }
        let hourLabel: (Date) -> String = { date in
            DateFormatter.localizedString(from: date,
                dateStyle: .none,
                timeStyle: .short)
        }

        var usage: [Date: [String: TimeInterval]] = [:]

        var deviceCount = 0, segmentCount = 0, appCount = 0
        for await device in data {
            deviceCount += 1
            for await segment in device.activitySegments {
                segmentCount += 1
                let hourStart = segment.dateInterval.start
                for await category in segment.categories {
                    for await app in category.applications {
                        let id = app.application.bundleIdentifier ?? "unknown"
                        usage[hourStart, default: [:]][id, default: 0] +=
                            app.totalActivityDuration
                        appCount += 1
                    }
                }
            }
        }

        log.debug("📱 Devices: \(deviceCount), segments: \(segmentCount), apps: \(appCount)")

        guard appCount > 0 else {
            return """
                   No Screen-Time data found.
                   • Has the host app called AuthorizationCenter.shared.requestAuthorization(for: .individual)?
                   • Is your DeviceActivityFilter’s applications set (tokens) non-empty?
                   """
        }

        // CSV rows
        var rows: [String] = []
        for (hour, apps) in usage.sorted(by: { $0.key < $1.key }) {
            let label = hourLabel(hour)
            for (bundleID, secs) in apps.sorted(by: { $0.key < $1.key }) {
                rows.append("\(label)|\(bundleID)|\(minutesFmt(secs))")
            }
        }

        return rows.joined(separator: "\n")
    }
}
