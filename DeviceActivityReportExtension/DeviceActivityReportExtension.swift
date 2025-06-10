//
//  DeviceActivityReportExtension.swift
//  DeviceActivityReportExtension
//
//  Created by Savina Jabbo on 6/10/25.
//

import DeviceActivity
import SwiftUI

@main
struct DeviceActivityReportApp: DeviceActivityReportExtension {
    var body: some DeviceActivityReportScene {
        TotalActivityReport { activityData in
            TotalActivityView(activityReport: activityData)
        }
    }
}
