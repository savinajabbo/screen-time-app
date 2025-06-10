//
//  TotalActivityReport.swift
//  DeviceActivityReportExtension
//
//  Created by Savina Jabbo on 6/10/25.
//

import DeviceActivity
import SwiftUI

extension DeviceActivityReport.Context {
    static let total = Self("TotalActivity")
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .total
    
    let content: (String) -> TotalActivityView
    
    func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>) async -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .dropAll

        let thisDevice = await UIDevice.current.model

        guard let deviceData = await data.first(where: { deviceData in
            guard let deviceName = deviceData.device.name else { return false }
            return deviceName.localizedCaseInsensitiveContains("iPhone")
        }) else {
            return "No iPhone data available\nDevice: \(thisDevice)"
        }

        let totalActivityDuration = await deviceData.activitySegments.reduce(0) { total, segment in
            total + segment.totalActivityDuration
        }

        var appNames = [String]()
        appNames.append("\(thisDevice),Time: \(formatter.string(from: totalActivityDuration) ?? "No time data")")

        for await activitySegment in deviceData.activitySegments {
            for await category in activitySegment.categories {
                for await app in category.applications {
                    let appName = app.application.localizedDisplayName ?? "Unknown App"
                    let appTime = formatter.string(from: app.totalActivityDuration) ?? "No Time"
                    appNames.append("\(appName),Time:\(appTime)")
                }
            }
        }

        let result = appNames.joined(separator: "\n")
        return result.isEmpty ? "No activity data found" : result
    }
}
