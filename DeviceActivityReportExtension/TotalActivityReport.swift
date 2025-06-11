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
        print("🔍 TotalActivityReport: Processing data for device: \(thisDevice)")

        var deviceData: DeviceActivityData? = nil
        for await device in data {
            deviceData = device
            break
        }
        
        guard let deviceData = deviceData else {
            print("❌ TotalActivityReport: No device data available")
            return "No device data available\nDevice: \(thisDevice)"
        }

        print("✅ TotalActivityReport: Found device data")

        let totalActivityDuration = await deviceData.activitySegments.reduce(0) { total, segment in
            total + segment.totalActivityDuration
        }

        var appData = [String]()
        appData.append("Device:\(thisDevice)")
        appData.append("TotalTime:\(formatter.string(from: totalActivityDuration) ?? "0m")")

        var appCount = 0
        for await activitySegment in deviceData.activitySegments {
            print("🔍 Processing activity segment")
            
            for await category in activitySegment.categories {
                print("🔍 Processing category")
                
                for await app in category.applications {
                    let bundleId = app.application.bundleIdentifier ?? "unknown.bundle.id"
                    let appName = app.application.localizedDisplayName ?? bundleId
                    let appTime = formatter.string(from: app.totalActivityDuration) ?? "0m"
                    
                    appData.append("\(bundleId)|\(appName)|\(appTime)")
                    appCount += 1
                    print("✅ Added app: \(appName) (\(bundleId)) - \(appTime)")
                }
            }
        }

        print("📊 TotalActivityReport: Processed \(appCount) apps total")
        let result = appData.joined(separator: "\n")
        print("🔍 TotalActivityReport: Final result: \(result)")
        return result.isEmpty ? "No activity data found\nDevice: \(thisDevice)" : result
    }
}
