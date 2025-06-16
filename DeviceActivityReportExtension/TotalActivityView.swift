//
//  TotalActivityView.swift
//  DeviceActivityReportExtension
//
//  Created by Savina Jabbo on 6/10/25.
//

import SwiftUI
import DeviceActivity

struct AppUsageData: Identifiable, Codable {
    let id = UUID()
    let bundleIdentifier: String
    let name: String
    let timeString: String
    let timeInSeconds: TimeInterval
    let hour: String
    
    var formattedTime: String {
        return timeString
    }
}

struct TotalActivityView: View {
    let activityReport: String
    
    @State private var processedApps: [AppUsageData] = []
    @State private var debugInfo: String = "Starting..."
    @State private var deviceInfo: String = ""
    @State private var totalTime: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Usage Timeline")
                .font(.title2)
                .bold()
            
            Text("Debug: \(debugInfo)")
                .font(.caption)
                .foregroundColor(.orange)
            
            if processedApps.isEmpty {
                Text("Processing screen time data...")
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(groupedByHour.keys.sorted(by: { parseHourForSorting($0) < parseHourForSorting($1) }), id: \.self) { hour in
                            HourTimelineView(hour: hour, apps: groupedByHour[hour] ?? [])
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding()
        .onAppear {
            debugInfo = "Processing report data"
            processReportData()
        }
    }
    
    // Computed property to group apps by hour
    private var groupedByHour: [String: [AppUsageData]] {
        Dictionary(grouping: processedApps) { $0.hour }
    }
    
    private func processReportData() {
        debugInfo = "Parsing activity report..."
        print("🔍 TotalActivityView: Processing report: \(activityReport)")
        
        let lines = activityReport.split(separator: "\n")
        var apps: [AppUsageData] = []
        
        // Check if this is the new CSV format or an error message
        if activityReport.contains("No Screen-Time data found") {
            debugInfo = "No Screen-Time data found"
            return
        }
        
        for line in lines {
            let lineString = String(line).trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            guard !lineString.isEmpty else { continue }
            
            // New CSV format: hour|bundleID|minutes
            let parts = lineString.split(separator: "|")
            guard parts.count == 3 else { 
                print("Skipping malformed line: \(lineString)")
                continue 
            }
            
            let hour = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let bundleId = String(parts[1]).trimmingCharacters(in: .whitespaces)
            let minutesString = String(parts[2]).trimmingCharacters(in: .whitespaces)
            
            // Convert minutes to seconds
            let minutes = Double(minutesString) ?? 0
            let timeInSeconds = minutes * 60
            let timeString = "\(Int(minutes))m"
            
            // Use bundle ID as display name (we could enhance this with a lookup table)
            let appName = bundleIdToDisplayName(bundleId)
            
            apps.append(AppUsageData(
                bundleIdentifier: bundleId,
                name: appName,
                timeString: timeString,
                timeInSeconds: timeInSeconds,
                hour: hour
            ))
            
            print("Processed app: \(appName) (\(bundleId)) at \(hour) - \(timeString)")
        }
        
        processedApps = apps.sorted { app1, app2 in
            // First sort by hour (chronologically)
            let hour1 = parseHourForSorting(app1.hour)
            let hour2 = parseHourForSorting(app2.hour)
            if hour1 != hour2 {
                return hour1 < hour2
            }
            // Within the same hour, sort by usage time (most used first)
            return app1.timeInSeconds > app2.timeInSeconds
        }
        debugInfo = "Found \(processedApps.count) hourly app usage entries"
        print("TotalActivityView: Final count: \(processedApps.count) entries")
        
        saveDataToMainApp(processedApps)
    }
    
    // Helper to convert bundle ID to a more readable name
    private func bundleIdToDisplayName(_ bundleId: String) -> String {
        let knownApps = [
            "com.apple.mobilesafari": "Safari",
            "com.apple.mobilemail": "Mail",
            "com.apple.MobileSMS": "Messages",
            "com.apple.Music": "Music",
            "com.apple.camera": "Camera",
            "com.apple.Photos": "Photos",
            "com.apple.AppStore": "App Store",
            "com.apple.mobilephone": "Phone",
            "com.apple.MobileAddressBook": "Contacts",
            "com.apple.Preferences": "Settings",
            "com.apple.calculator": "Calculator",
            "com.apple.Maps": "Maps",
            "com.apple.weather": "Weather",
            "com.apple.mobilecal": "Calendar",
            "com.apple.mobilenotes": "Notes",
            "com.apple.reminders": "Reminders",
            "com.apple.facetime": "FaceTime",
            "com.apple.iBooks": "Books",
            "com.apple.news": "News",
            "com.apple.podcasts": "Podcasts",
            "com.apple.tv": "Apple TV",
            "com.apple.findmy": "Find My",
            "com.apple.shortcuts": "Shortcuts"
        ]
        
        return knownApps[bundleId] ?? bundleId.components(separatedBy: ".").last?.capitalized ?? bundleId
    }
    
    // Helper to parse hour strings for chronological sorting
    private func parseHourForSorting(_ hourString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        if let date = formatter.date(from: hourString) {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            return hour
        }
        
        // Fallback: try to extract hour number from string
        let numbers = hourString.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
        return numbers.first ?? 0
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

// New timeline view for each hour
struct HourTimelineView: View {
    let hour: String
    let apps: [AppUsageData]
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Hour label (left side)
            VStack {
                Text(hour)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)
                    .frame(width: 60, alignment: .trailing)
                
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
                
                if apps.count > 1 {
                    Rectangle()
                        .fill(.blue.opacity(0.3))
                        .frame(width: 2, height: CGFloat(apps.count - 1) * 32)
                }
            }
            
            // Apps used during this hour (right side)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(apps.sorted { $0.timeInSeconds > $1.timeInSeconds }) { app in
                    HStack {
                        // App icon placeholder
                        RoundedRectangle(cornerRadius: 6)
                            .fill(colorForApp(app.bundleIdentifier))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(String(app.name.prefix(1)))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(app.formattedTime)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Usage bar
                        if let maxUsage = apps.map(\.timeInSeconds).max(), maxUsage > 0 {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colorForApp(app.bundleIdentifier).opacity(0.7))
                                .frame(width: CGFloat(app.timeInSeconds / maxUsage) * 60, height: 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // Generate consistent colors for apps
    private func colorForApp(_ bundleId: String) -> Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .red, .pink, .cyan, .mint, .indigo, .teal]
        let hash = abs(bundleId.hashValue)
        return colors[hash % colors.count]
    }
}


