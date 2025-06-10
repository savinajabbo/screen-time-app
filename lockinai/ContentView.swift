//
//  ContentView.swift
//  lockinai
//
//  Created by Savina Jabbo on 5/31/25.
//

import SwiftUI
import FamilyControls
import DeviceActivity

extension DeviceActivityReport.Context {
    static let total = Self("TotalActivity")
}

struct ContentView: View {
    @StateObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var isLoading = false
    @State private var showingFamilyActivityPicker = false
    @State private var showingScreenTimeReport = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    Text("Screen Time Data Viewer")
                        .font(.title)
                        .bold()
                }
                .padding(.top)
                
                HStack {
                    Circle()
                        .fill(screenTimeManager.isAuthorized ? .green : .red)
                        .frame(width: 12, height: 12)
                    Text(screenTimeManager.isAuthorized ? "Screen Time Authorized" : "Not Authorized")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 12) {
                    if !screenTimeManager.isAuthorized {
                        Button("Request Screen Time Permission") {
                            Task {
                                do {
                                    try await screenTimeManager.requestAuthorization()
                                } catch {
                                    print("Authorization failed: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        VStack(spacing: 12) {
                            Button(showingScreenTimeReport ? "Hide Screen Time Data" : "Show Real Screen Time Data") {
                                showingScreenTimeReport.toggle()
                                if showingScreenTimeReport {
                                    screenTimeManager.startReportMonitoring()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            HStack(spacing: 12) {
                                Button("Fetch Extension Data") {
                                    isLoading = true
                                    Task {
                                        await screenTimeManager.fetchRealUsageData()
                                        isLoading = false
                                    }
                                }
                                .buttonStyle(.bordered)
                                
                                Button("iOS Settings") {
                                    screenTimeManager.openScreenTimeSettings()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                if showingScreenTimeReport && screenTimeManager.isAuthorized {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Screen Time Report")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        DeviceActivityReport(.total)
                            .frame(minHeight: 250, maxHeight: 400)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                }
                
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading screen time data from extension...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if !screenTimeManager.appUsageData.isEmpty {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Extension Data")
                                .font(.headline)
                            Spacer()
                            Text("Last updated: \(Date(), formatter: timeFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        
                        List(screenTimeManager.appUsageData.prefix(10)) { app in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(app.name)
                                        .font(.subheadline)
                                        .bold()
                                    Text(app.bundleIdentifier)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(screenTimeManager.formatTimeInterval(app.totalTime))
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(.blue)
                                    Text("Last used")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(PlainListStyle())
                        .frame(maxHeight: 200)
                    }
                } else if !showingScreenTimeReport {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No screen time data loaded")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Use the buttons above to access your screen time data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Screen Time")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            screenTimeManager.checkAuthorizationStatus()
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    ContentView()
}

