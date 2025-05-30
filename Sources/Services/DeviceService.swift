import Foundation

actor DeviceService {
    private let deviceApiService: DeviceAPIService
    private let tokenService: TokenService
    private let storageService: StorageService
    private let key = "clix_device_id"

    init(
        storageService: StorageService,
        tokenService: TokenService,
        deviceApiService: DeviceAPIService = DeviceAPIService()
    ) {
        self.storageService = storageService
        self.tokenService = tokenService
        self.deviceApiService = deviceApiService
    }

    func getCurrentDeviceId() async -> String {
        if let id: String = await storageService.get(forKey: key) {
            return id
        }
        let newId = UUID().uuidString
        await storageService.set(newId, forKey: key)
        return newId
    }

    func setProjectUserId(_ projectUserId: String) async throws {
        guard let deviceId = await Clix.shared.getEnvironment()?.deviceId else { return }
        try await deviceApiService.setProjectUserId(deviceId: deviceId, projectUserId: projectUserId)
    }

    func removeProjectUserId() async throws {
        try await removeUserProperties(["userId"])
    }

    func updateUserProperties(_ properties: [String: Any]) async throws {
        guard let deviceId = await Clix.shared.getEnvironment()?.deviceId else { return }
        let propertiesList = properties.map { name, value in ClixUserProperty.of(name: name, value: value) }
        print("propertiesList:\(propertiesList), properties:\(properties)")
        try await deviceApiService.upsertUserProperties(deviceId: deviceId, properties: propertiesList)
    }

    func removeUserProperties(_ names: [String]) async throws {
        guard let deviceId = await Clix.shared.getEnvironment()?.deviceId else { return }
        try await deviceApiService.removeUserProperties(deviceId: deviceId, propertyNames: names)
    }

    func upsertToken(_ token: String, tokenType: String = "APNS") async throws {
        guard let environment = await Clix.shared.getEnvironment() else { return }
        let device = await environment.getDevice()
        let updatedDevice = ClixDevice(
            id: device.id,
            platform: device.platform,
            model: device.model,
            manufacturer: device.manufacturer,
            osName: device.osName,
            osVersion: device.osVersion,
            localeRegion: device.localeRegion,
            localeLanguage: device.localeLanguage,
            timezone: device.timezone,
            appName: device.appName,
            appVersion: device.appVersion,
            sdkType: device.sdkType,
            sdkVersion: device.sdkVersion,
            adId: device.adId,
            isPushPermissionGranted: true,
            pushToken: token,
            pushTokenType: tokenType
        )
        await environment.setDevice(updatedDevice)
        try await deviceApiService.upsertDevice(device: updatedDevice)
    }
}
