//
//  TotalActivityView.swift
//  DeviceActivityReportExtension
//
//  Created by Savina Jabbo on 6/10/25.
//

import SwiftUI
import DeviceActivity

struct TotalActivityView: View {
    let activityReport: String
    
    @State private var processedApps: [AppUsageData] = []
    @State private var debugInfo: String = "Starting..."
    @State private var deviceInfo: String = ""
    @State private var totalTime: String = ""
    
    struct AppUsageData: Identifiable, Codable {
        let id = UUID()
        let bundleIdentifier: String
        let name: String
        let timeString: String
        let timeInSeconds: TimeInterval
        
        var formattedTime: String {
            return timeString
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Screen Time Report")
                .font(.title2)
                .bold()
            
            if !deviceInfo.isEmpty {
                Text("Device: \(deviceInfo)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            if !totalTime.isEmpty {
                Text("Total Screen Time: \(totalTime)")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Text("Debug: \(debugInfo)")
                .font(.caption)
                .foregroundColor(.orange)
            
            if processedApps.isEmpty {
                Text("Processing screen time data...")
                    .foregroundColor(.secondary)
            } else {
                Text("Found \(processedApps.count) apps:")
                    .font(.headline)
                
                List(processedApps) { app in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.name)
                                .font(.subheadline)
                                .bold()
                            Text(app.bundleIdentifier)
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("Usage: \(app.formattedTime)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        if let maxUsage = processedApps.map(\.timeInSeconds).max(), maxUsage > 0 {
                            ProgressView(value: app.timeInSeconds / maxUsage)
                                .frame(width: 60)
                                .accentColor(.blue)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .onAppear {
            debugInfo = "Processing report data"
            processReportData()
        }
    }
    
    private func processReportData() {
        debugInfo = "Parsing activity report..."
        print("🔍 TotalActivityView: Processing report: \(activityReport)")
        
        let lines = activityReport.split(separator: "\n")
        var apps: [AppUsageData] = []
        
        for line in lines {
            let lineString = String(line).trimmingCharacters(in: .whitespaces)
            
            // device info
            if lineString.hasPrefix("Device:") {
                deviceInfo = String(lineString.dropFirst(7))
                continue
            }
            
            // total time
            if lineString.hasPrefix("TotalTime:") {
                totalTime = String(lineString.dropFirst(10))
                continue
            }
            
            // app data: bundleId|appName|timeString
            let parts = lineString.split(separator: "|")
            guard parts.count == 3 else { 
                print("Skipping malformed line: \(lineString)")
                continue 
            }
            
            let bundleId = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let appName = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let timeString = String(parts[2]).trimmingCharacters(in: .whitespaces)
            
            let timeInSeconds = parseTimeString(timeString)
            
            apps.append(AppUsageData(
                bundleIdentifier: bundleId,
                name: appName,
                timeString: timeString,
                timeInSeconds: timeInSeconds
            ))
            
            print("Processed app: \(appName) (\(bundleId)) - \(timeString)")
        }
        
        processedApps = apps.sorted { $0.timeInSeconds > $1.timeInSeconds }
        debugInfo = "Found \(processedApps.count) apps with screen time data"
        print("TotalActivityView: Final count: \(processedApps.count) apps")
        
        saveDataToMainApp(processedApps)
    }
    
    private func parseTimeString(_ timeString: String) -> TimeInterval {
        var totalSeconds: TimeInterval = 0
        let components = timeString.split(separator: " ")
        
        for component in components {
            if component.hasSuffix("h"), let hours = Double(component.dropLast()) {
                totalSeconds += hours * 3600
            } else if component.hasSuffix("m"), let minutes = Double(component.dropLast()) {
                totalSeconds += minutes * 60
            } else if component.hasSuffix("s"), let seconds = Double(component.dropLast()) {
                totalSeconds += seconds
            }
        }
        
        return totalSeconds
    }
    
    private func saveDataToMainApp(_ data: [AppUsageData]) {
        guard let userDefaults = UserDefaults(suiteName: "group.savinajabbo.lockin") else {
            print("Failed to access App Group UserDefaults")
            return
        }
        
        // structured data for main app
        let extensionData = data.map { app in
            [
                "bundleIdentifier": app.bundleIdentifier,
                "displayName": app.name,
                "totalTime": app.timeInSeconds,
                "numberOfPickups": 0,
                "firstPickupDate": Date().timeIntervalSince1970,
                "lastPickupDate": Date().timeIntervalSince1970
            ] as [String : Any]
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: extensionData)
            userDefaults.set(jsonData, forKey: "appUsageData")
            userDefaults.set(Date(), forKey: "lastDataUpdate")
            print("Saved \(data.count) apps to App Group UserDefaults")
        } catch {
            print("Failed to save data: \(error)")
        }
    }
}


