import Foundation
import ScreenTime
import FamilyControls
import DeviceActivity
import ManagedSettings

class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var isAuthorized: Bool = false
    @Published var isMonitoring: Bool = false
    @Published var selectedApps: FamilyActivitySelection = FamilyActivitySelection()
    @Published var appUsageData: [AppUsageInfo] = []
    
    private let deviceActivityCenter = DeviceActivityCenter()
    private let managedSettingsStore = ManagedSettingsStore()
    
    struct AppUsageInfo: Identifiable {
        let id = UUID()
        let bundleIdentifier: String
        let name: String
        let totalTime: TimeInterval
        let lastUsed: Date
    }
    
    private init() {}
    
    func requestAuthorization() async throws {
        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
        await MainActor.run {
            self.isAuthorized = true
        }
        print("Screen Time authorization granted")
    }
    
    func startMonitoring() {
        guard isAuthorized else {
            print("Error: Not authorized for Screen Time")
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        let activityName = DeviceActivityName("DailyUsageMonitoring")
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            isMonitoring = true
            print("✅ Started monitoring device activity")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }
    
    func startReportMonitoring() {
        guard isAuthorized else {
            print("❌ Error: Not authorized for Screen Time")
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute], from: startOfDay),
            intervalEnd: calendar.dateComponents([.hour, .minute], from: now),
            repeats: false
        )
        
        let activityName = DeviceActivityName("ReportMonitoring")
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            print("✅ Started report monitoring for DeviceActivityReport")
        } catch {
            print("❌ Failed to start report monitoring: \(error)")
        }
    }
    
    func stopMonitoring() {
        let activityName = DeviceActivityName("DailyUsageMonitoring")
        deviceActivityCenter.stopMonitoring([activityName])
        isMonitoring = false
        print("Stopped monitoring device activity")
    }
    
    func fetchRealUsageData() async {
        guard isAuthorized else {
            print("❌ Error: Not authorized for Screen Time")
            return
        }
        
        print("🔄 Starting to fetch real usage data...")
        
        startMonitoring()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        loadUsageDataFromExtension()
        
        if appUsageData.isEmpty {
            await fetchDataDirectly()
        }
        
        if appUsageData.isEmpty {
            await showDataLimitation()
        }
    }
    
    private func fetchDataDirectly() async {
        print("🔄 Attempting direct screen time data access...")
        
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        let schedule = DeviceActivitySchedule(
            intervalStart: calendar.dateComponents([.hour, .minute], from: startOfToday),
            intervalEnd: calendar.dateComponents([.hour, .minute], from: now),
            repeats: false
        )
        
        let activityName = DeviceActivityName("DirectDataAccess")
        
        do {
            try deviceActivityCenter.startMonitoring(activityName, during: schedule)
            print("✅ Started direct monitoring for today's data")
            
            try await Task.sleep(nanoseconds: 5_000_000_000) 
            
            loadUsageDataFromExtension()
            
            if !appUsageData.isEmpty {
                print("✅ Successfully loaded real usage data!")
            } else {
                print("⚠️ No real data available yet - extension may need more time")
            }
            
        } catch {
            print("❌ Failed direct monitoring: \(error)")
        }
    }
    
    private func loadUsageDataFromExtension() {
        guard let userDefaults = UserDefaults(suiteName: "group.savinajabbo.lockinai") else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        if let data = userDefaults.data(forKey: "appUsageData") {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([ExtensionAppUsageData].self, from: data) {
                let convertedData = decodedData.map { extensionData in
                    AppUsageInfo(
                        bundleIdentifier: extensionData.bundleIdentifier,
                        name: extensionData.displayName,
                        totalTime: extensionData.totalTime,
                        lastUsed: extensionData.lastPickupDate ?? Date()
                    )
                }
                
                DispatchQueue.main.async {
                    self.appUsageData = convertedData.sorted { $0.totalTime > $1.totalTime }
                    print("✅ Loaded real usage data for \(convertedData.count) apps from extension")
                }
            }
        } else {
            print("⚠️  No usage data found from extension yet")
        }
    }
    
    private func createSampleData() async {
        let sampleData = [
            AppUsageInfo(
                bundleIdentifier: "com.apple.mobilesafari",
                name: "Safari",
                totalTime: 3600, 
                lastUsed: Date().addingTimeInterval(-300)
            ),
            AppUsageInfo(
                bundleIdentifier: "com.apple.mobilemail",
                name: "Mail",
                totalTime: 1800, 
                lastUsed: Date().addingTimeInterval(-600)
            ),
            AppUsageInfo(
                bundleIdentifier: "com.apple.MobileSMS",
                name: "Messages",
                totalTime: 2400, 
                lastUsed: Date().addingTimeInterval(-120)
            ),
            AppUsageInfo(
                bundleIdentifier: "com.savinajabbo.lockinai",
                name: "LockIn AI",
                totalTime: 420, 
                lastUsed: Date()
            )
        ]
        
        await MainActor.run {
            self.appUsageData = sampleData.sorted { $0.totalTime > $1.totalTime }
            print("✅ Created sample data to demonstrate functionality")
        }
    }
    
    private struct ExtensionAppUsageData: Codable {
        let bundleIdentifier: String
        let displayName: String
        let totalTime: TimeInterval
        let numberOfPickups: Int
        let firstPickupDate: Date?
        let lastPickupDate: Date?
    }
    
    func blockSelectedApps() {
        guard !selectedApps.applicationTokens.isEmpty else {
            print("No apps selected to block")
            return
        }
        
        managedSettingsStore.shield.applications = selectedApps.applicationTokens
        print("✅ Blocked \(selectedApps.applicationTokens.count) apps")
    }
    
    func unblockAllApps() {
        managedSettingsStore.shield.applications = []
        print("✅ Unblocked all apps")
    }
    
    func checkAuthorizationStatus() {
        Task {
            let status = AuthorizationCenter.shared.authorizationStatus
            await MainActor.run {
                self.isAuthorized = (status == .approved)
            }
            print("Authorization status: \(status)")
        }
    }
    
    func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    private func showDataLimitation() async {
        let limitationData = [
            AppUsageInfo(
                bundleIdentifier: "limitation.info",
                name: "ℹ️ Screen Time Data Access",
                totalTime: 0,
                lastUsed: Date()
            ),
            AppUsageInfo(
                bundleIdentifier: "limitation.apple",
                name: "🔒 Apple restricts direct access",
                totalTime: 0,
                lastUsed: Date()
            ),
            AppUsageInfo(
                bundleIdentifier: "limitation.solution",
                name: "💡 Use 'Open Screen Time Settings'",
                totalTime: 0,
                lastUsed: Date()
            )
        ]
        
        await MainActor.run {
            self.appUsageData = limitationData
            print("ℹ️ Showing Screen Time access limitation info")
        }
    }
    
    func openScreenTimeSettings() {
        guard let settingsUrl = URL(string: "App-prefs:SCREEN_TIME") else {
            print("❌ Unable to create Screen Time settings URL")
            return
        }
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
                print("✅ Opening Screen Time settings")
            } else {
                print("❌ Cannot open Screen Time settings")
            }
        }
    }
} 
