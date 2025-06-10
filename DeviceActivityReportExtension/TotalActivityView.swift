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
    
    struct AppUsageData: Identifiable, Codable {
        let id = UUID()
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
        
        let lines = activityReport.split(separator: "\n")
        var apps: [AppUsageData] = []
        
        for line in lines {
            let parts = line.split(separator: ",")
            guard parts.count == 2 else { continue }
            
            let name = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let timeString = String(parts[1])
                .replacingOccurrences(of: "Time:", with: "")
                .trimmingCharacters(in: .whitespaces)
            
            let timeInSeconds = parseTimeString(timeString)
            
            apps.append(AppUsageData(
                name: name,
                timeString: timeString,
                timeInSeconds: timeInSeconds
            ))
        }
        
        processedApps = apps.sorted { $0.timeInSeconds > $1.timeInSeconds }
        debugInfo = "Found \(processedApps.count) apps with screen time data"
        
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
        guard let userDefaults = UserDefaults(suiteName: "group.savinajabbo.lockinai") else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        let encoder = JSONEncoder()
        do {
            let simplified = data.map { app in
                [
                    "bundleIdentifier": app.name,
                    "displayName": app.name,
                    "totalTime": app.timeInSeconds,
                    "numberOfPickups": 0,
                    "firstPickupDate": Date().timeIntervalSince1970,
                    "lastPickupDate": Date().timeIntervalSince1970
                ]
            }
            let encoded = try JSONSerialization.data(withJSONObject: simplified)
            userDefaults.set(encoded, forKey: "appUsageData")
            userDefaults.set(Date(), forKey: "lastDataUpdate")
            print("✅ Saved \(data.count) apps to App Group UserDefaults")
        } catch {
            print("❌ Failed to save data: \(error)")
        }
    }
}


