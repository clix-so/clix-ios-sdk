import Foundation
import MMKV

struct StorageInitializer {
  private static let migrationFlagKey = "clix_storage_migrated"

  private struct AppGroupConfig {
    let appGroupId: String?
    let projectId: String
    let type: AppGroupType

    enum AppGroupType {
      case bundleId, projectId, none
    }
  }

  static func initializeStorage(projectId: String) async -> any Storage {
    let bundleId = BundleIdentifier.main
    let appGroupConfig = determineAppGroup(projectId: projectId, bundleId: bundleId)

    guard appGroupConfig.type == .bundleId else {
      return await initializeWithProjectIdOrDefault(
        projectId: projectId,
        config: appGroupConfig
      )
    }
    return await initializeWithBundleIdAppGroup(
      projectId: projectId,
      bundleId: bundleId,
      config: appGroupConfig
    )
  }

  private static func determineAppGroup(
    projectId: String,
    bundleId: String
  ) -> AppGroupConfig {
    let bundleIdAppGroupId = BundleIdentifier.bundleIdBasedAppGroupId(bundleId: bundleId)
    if FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: bundleIdAppGroupId
    ) != nil {
      return AppGroupConfig(
        appGroupId: bundleIdAppGroupId,
        projectId: projectId,
        type: .bundleId
      )
    }

    let projectIdAppGroupId = BundleIdentifier.projectIdBasedAppGroupId(projectId: projectId)
    if FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: projectIdAppGroupId
    ) != nil {
      return AppGroupConfig(
        appGroupId: projectIdAppGroupId,
        projectId: projectId,
        type: .projectId
      )
    }

    return AppGroupConfig(
      appGroupId: nil,
      projectId: projectId,
      type: .none
    )
  }

  private static func initializeWithBundleIdAppGroup(
    projectId: String,
    bundleId: String,
    config: AppGroupConfig
  ) async -> any Storage {
    guard let bundleIdAppGroupId = config.appGroupId else {
      ClixLogger.error("BundleId app group is nil, falling back to projectId storage")
      let fallback = determineAppGroup(projectId: projectId, bundleId: bundleId)
      return await initializeWithProjectIdOrDefault(projectId: projectId, config: fallback)
    }

    let bundleIdStorage = MmkvStorage(projectId: config.projectId, appGroupId: bundleIdAppGroupId)

    let isCompleted = await isMigrationCompleted(storage: bundleIdStorage)
    if !isCompleted {
      ClixLogger.info("Starting unified storage migration to bundleId-based MMKV...")
      await migrateAllDataToBundleIdStorage(
        projectId: projectId,
        bundleId: bundleId,
        destinationStorage: bundleIdStorage,
        bundleIdAppGroupId: bundleIdAppGroupId
      )
      await markMigrationComplete(storage: bundleIdStorage)
      ClixLogger.info("Unified storage migration completed successfully")
    }

    return bundleIdStorage
  }

  private static func initializeWithProjectIdOrDefault(
    projectId: String,
    config: AppGroupConfig
  ) async -> any Storage {
    ClixLogger.debug("Using projectId-based or default storage")

    let userDefaultsStorage = UserDefaultsStorage(appGroupId: config.appGroupId)
    let mmkvStorage = MmkvStorage(projectId: config.projectId, appGroupId: config.appGroupId)

    await StorageTypeMigrator.migrateIfNeeded(from: userDefaultsStorage, to: mmkvStorage)

    return mmkvStorage
  }

  private static func migrateAllDataToBundleIdStorage(
    projectId: String,
    bundleId: String,
    destinationStorage: MmkvStorage,
    bundleIdAppGroupId: String
  ) async {
    await migrateFromProjectIdMmkv(
      projectId: projectId,
      destinationStorage: destinationStorage
    )

    await migrateFromProjectIdUserDefaults(
      projectId: projectId,
      destinationStorage: destinationStorage
    )

    await migrateFromBundleIdUserDefaults(
      bundleIdAppGroupId: bundleIdAppGroupId,
      destinationStorage: destinationStorage
    )

    await migrateFromStandardUserDefaults(
      destinationStorage: destinationStorage
    )
  }

  private static func migrateFromProjectIdMmkv(
    projectId: String,
    destinationStorage: MmkvStorage
  ) async {
    let projectIdAppGroupId = BundleIdentifier.projectIdBasedAppGroupId(projectId: projectId)

    guard FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: projectIdAppGroupId
    ) != nil else {
      ClixLogger.debug("ProjectId-based App Group not available, skipping MMKV migration")
      return
    }

    let projectIdStorage = MmkvStorage(projectId: projectId, appGroupId: projectIdAppGroupId)

    let migratedCount = await migrateAndDeleteFromSource(
      from: projectIdStorage,
      to: destinationStorage,
      sourceName: "projectId-based MMKV"
    )

    if migratedCount > 0 {
      ClixLogger.info("Migrated \(migratedCount) keys from projectId-based MMKV")
    }
  }

  private static func migrateFromProjectIdUserDefaults(
    projectId: String,
    destinationStorage: MmkvStorage
  ) async {
    let projectIdAppGroupId = BundleIdentifier.projectIdBasedAppGroupId(projectId: projectId)

    guard FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: projectIdAppGroupId
    ) != nil else {
      ClixLogger.debug("ProjectId-based App Group not available, skipping UserDefaults migration")
      return
    }

    let projectIdUserDefaults = UserDefaultsStorage(appGroupId: projectIdAppGroupId)

    let migratedCount = await migrateAndDeleteFromSource(
      from: projectIdUserDefaults,
      to: destinationStorage,
      sourceName: "projectId-based UserDefaults"
    )

    if migratedCount > 0 {
      ClixLogger.info("Migrated \(migratedCount) keys from projectId-based UserDefaults")
    }
  }

  private static func migrateFromBundleIdUserDefaults(
    bundleIdAppGroupId: String,
    destinationStorage: MmkvStorage
  ) async {
    let bundleIdUserDefaults = UserDefaultsStorage(appGroupId: bundleIdAppGroupId)

    let migratedCount = await migrateAndDeleteFromSource(
      from: bundleIdUserDefaults,
      to: destinationStorage,
      sourceName: "bundleId-based UserDefaults"
    )

    if migratedCount > 0 {
      ClixLogger.info("Migrated \(migratedCount) keys from bundleId-based UserDefaults")
    }
  }

  private static func migrateFromStandardUserDefaults(
    destinationStorage: MmkvStorage
  ) async {
    let standardUserDefaults = UserDefaultsStorage(appGroupId: nil)

    let migratedCount = await migrateAndDeleteFromSource(
      from: standardUserDefaults,
      to: destinationStorage,
      sourceName: "standard UserDefaults"
    )

    if migratedCount > 0 {
      ClixLogger.info("Migrated \(migratedCount) keys from standard UserDefaults")
    }
  }

  private static func migrateAndDeleteFromSource(
    from source: any Storage,
    to destination: any Storage,
    sourceName: String
  ) async -> Int {
    var migratedCount = 0

    ClixLogger.debug("Attempting migration from \(sourceName)...")
    for key in StorageMigrator.knownStorageKeys {
      if let data = await source.getRawData(key) {
        await destination.setRawData(key, data)
        await source.remove(key)
        migratedCount += 1
        ClixLogger.debug("Migrated and deleted key from \(sourceName): \(key) (\(data.count) bytes)")
      } else {
        ClixLogger.debug("No data found for key in \(sourceName): \(key)")
      }
    }

    if migratedCount > 0 {
      await source.synchronize()
      await destination.synchronize()
      ClixLogger.info("Successfully migrated \(migratedCount) keys from \(sourceName)")
    } else {
      ClixLogger.debug("No data to migrate from \(sourceName)")
    }

    return migratedCount
  }

  private static func isMigrationCompleted(storage: MmkvStorage) async -> Bool {
    let value: Bool? = await storage.get(migrationFlagKey)
    return value ?? false
  }

  private static func markMigrationComplete(storage: MmkvStorage) async {
    await storage.set(migrationFlagKey, true)
    await storage.synchronize()
    ClixLogger.debug("Marked storage initialization as complete")
  }
}
