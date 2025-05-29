import Foundation

/// Class to handle shared UserDefaults between main app and extension using App Groups
public class ClixUserDefault {
    // Constants for UserDefaults keys
    private enum Keys {
        static let projectId = "clix_project_id"
        static let apiKey = "clix_api_key"
        static let endpoint = "clix_endpoint"
        static let appGroupId = "clix_app_group_id"
        static let extraHeaders = "clix_extra_headers"
    }
    
    // Shared instance
    public static let shared = ClixUserDefault()
    
    // UserDefaults instance
    private var userDefaults: UserDefaults?
    
    /// Generates a standard app group ID based on the project ID
    /// This ensures that both the main app and extensions use the same app group ID
    /// - Parameter projectId: The Clix project ID
    /// - Returns: Generated app group ID in the format "group.clix.{project_id}"
    public static func getAppGroupId(projectId: String) -> String {
        // Sanitize project ID to ensure it's valid for app group ID
        // Remove any characters that aren't alphanumeric, periods, or hyphens
        let sanitizedProjectId = projectId.replacingOccurrences(of: "[^a-zA-Z0-9.-]", with: "-", options: .regularExpression)
        return "group.clix.\(sanitizedProjectId)"
    }
    
    // Initialize with default UserDefaults
    private init() {
        // Default to standard UserDefaults
        self.userDefaults = UserDefaults.standard
    }
    
    /// Configure with app group ID to use shared UserDefaults
    /// - Parameter appGroupId: App group identifier for sharing UserDefaults
    public func configure(appGroupId: String) {
        if let sharedDefaults = UserDefaults(suiteName: appGroupId) {
            NSLog("[ClixUserDefault] Successfully configured with app group: \(appGroupId)")
            self.userDefaults = sharedDefaults
            // Save the app group ID for reference
            sharedDefaults.set(appGroupId, forKey: Keys.appGroupId)
            sharedDefaults.synchronize()
            
            // Log current values for debugging
            let projectId = sharedDefaults.string(forKey: Keys.projectId) ?? "<not set>"
            let apiKey = sharedDefaults.string(forKey: Keys.apiKey) ?? "<not set>"
            let endpoint = sharedDefaults.string(forKey: Keys.endpoint) ?? "<not set>"
            NSLog("[ClixUserDefault] Current values - projectId: \(projectId), apiKey: \(apiKey), endpoint: \(endpoint)")
        } else {
            NSLog("[ClixUserDefault] Failed to initialize UserDefaults with app group: \(appGroupId)")
        }
    }
    
    /// Get the configured UserDefaults
    /// - Returns: UserDefaults instance
    public func getUserDefaults() -> UserDefaults {
        return userDefaults ?? UserDefaults.standard
    }
    
    /// Save Clix configuration to UserDefaults
    /// - Parameter config: ClixConfig instance
    public func saveConfig(_ config: ClixConfig) {
        guard let userDefaults = userDefaults else {
            NSLog("[ClixUserDefault] ERROR: UserDefaults not configured properly")
            return
        }
        
        NSLog("[ClixUserDefault] Saving config - projectId: \(config.projectId), apiKey: \(config.apiKey), endpoint: \(config.endpoint)")
        
        userDefaults.set(config.projectId, forKey: Keys.projectId)
        userDefaults.set(config.apiKey, forKey: Keys.apiKey)
        userDefaults.set(config.endpoint, forKey: Keys.endpoint)
        
        // Serialize extra headers as JSON
        if !config.extraHeaders.isEmpty {
            do {
                let data = try JSONSerialization.data(withJSONObject: config.extraHeaders)
                userDefaults.set(data, forKey: Keys.extraHeaders)
            } catch {
                NSLog("[ClixUserDefault] ERROR: Failed to serialize extra headers: \(error.localizedDescription)")
            }
        }
        
        // Force synchronize to ensure values are written to disk immediately
        let success = userDefaults.synchronize()
        NSLog("[ClixUserDefault] Saved Clix config to UserDefaults. Synchronize success: \(success)")
        
        // Verify values were saved correctly
        let savedProjectId = userDefaults.string(forKey: Keys.projectId) ?? "<not set>"
        let savedApiKey = userDefaults.string(forKey: Keys.apiKey) ?? "<not set>"
        let savedEndpoint = userDefaults.string(forKey: Keys.endpoint) ?? "<not set>"
        NSLog("[ClixUserDefault] Verified saved values - projectId: \(savedProjectId), apiKey: \(savedApiKey), endpoint: \(savedEndpoint)")
    }
    
    /// Get ProjectID from UserDefaults
    /// - Returns: Project ID string or empty string if not found
    public func getProjectId() -> String {
        return userDefaults?.string(forKey: Keys.projectId) ?? ""
    }
    
    /// Get API Key from UserDefaults
    /// - Returns: API Key string or empty string if not found
    public func getApiKey() -> String {
        return userDefaults?.string(forKey: Keys.apiKey) ?? ""
    }
    
    /// Get API endpoint from UserDefaults
    /// - Returns: Endpoint URL string or default if not found
    public func getEndpoint() -> String {
        return userDefaults?.string(forKey: Keys.endpoint) ?? "https://external-api-dev.clix.so"
    }
    
    /// Get extra headers from UserDefaults
    /// - Returns: Dictionary of extra headers or empty dictionary if not found
    public func getExtraHeaders() -> [String: String] {
        guard let data = userDefaults?.data(forKey: Keys.extraHeaders),
              let headers = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return headers
    }
    
    /// Get App Group ID from UserDefaults
    /// - Returns: App Group ID string or nil if not found
    public func getAppGroupId() -> String? {
        return userDefaults?.string(forKey: Keys.appGroupId)
    }
}
