import Foundation
import MMKV

struct AppGroupMigrator {
  private static let migrationFlagKey = "clix_app_group_migrated"

  static func migrateIfNeeded(projectId: String) async {
    let bundleId = BundleIdentifier.main
    let bundleIdAppGroupId = BundleIdentifier.bundleIdBasedAppGroupId(bundleId: bundleId)
    let projectIdAppGroupId = BundleIdentifier.projectIdBasedAppGroupId(projectId: projectId)

    guard FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: bundleIdAppGroupId
    ) != nil else {
      ClixLogger.debug("BundleId-based app group not configured, skipping migration")
      return
    }

    let bundleIdStorage = MmkvStorage(projectId: projectId, appGroupId: bundleIdAppGroupId)

    let isCompleted = await isMigrationCompleted(storage: bundleIdStorage)
    guard !isCompleted else {
      ClixLogger.debug("App group migration already completed")
      return
    }

    guard let projectIdGroupDir = FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: projectIdAppGroupId
    )?.path else {
      ClixLogger.debug("No projectId-based app group found, marking migration as complete")
      await markMigrationComplete(storage: bundleIdStorage)
      return
    }

    ClixLogger.info("Starting app group migration: \(projectIdAppGroupId) → \(bundleIdAppGroupId)")

    await migrateMmkvData(
      fromProjectId: projectId,
      destinationStorage: bundleIdStorage
    )

    await migrateUserDefaultsData(
      projectIdAppGroupId: projectIdAppGroupId,
      bundleIdAppGroupId: bundleIdAppGroupId
    )

    await markMigrationComplete(storage: bundleIdStorage)
    ClixLogger.info("App group migration completed successfully")
  }

  private static func migrateMmkvData(
    fromProjectId: String,
    destinationStorage: MmkvStorage
  ) async {
    let projectIdAppGroupId = BundleIdentifier.projectIdBasedAppGroupId(projectId: fromProjectId)
    let projectIdStorage = MmkvStorage(projectId: fromProjectId, appGroupId: projectIdAppGroupId)

    var migratedCount = 0

    for key in StorageMigrator.knownStorageKeys {
      if let data: Data = await projectIdStorage.get(key) {
        await destinationStorage.set(key, data)
        migratedCount += 1
        ClixLogger.debug("Migrated MMKV key: \(key)")
      }
    }

    if migratedCount > 0 {
      await projectIdStorage.synchronize()
      await destinationStorage.synchronize()
      ClixLogger.info("Migrated \(migratedCount) keys from projectId-based MMKV")
    }
  }

  private static func migrateUserDefaultsData(
    projectIdAppGroupId: String,
    bundleIdAppGroupId: String
  ) async {
    guard let projectIdDefaults = UserDefaults(suiteName: projectIdAppGroupId),
          let bundleIdDefaults = UserDefaults(suiteName: bundleIdAppGroupId) else {
      ClixLogger.debug("UserDefaults migration skipped")
      return
    }

    _ = await StorageMigrator.migrateUserDefaultsToUserDefaults(
      from: projectIdDefaults,
      to: bundleIdDefaults,
      keys: StorageMigrator.knownStorageKeys
    )
  }

  private static func isMigrationCompleted(storage: MmkvStorage) async -> Bool {
    let value: Bool? = await storage.get(migrationFlagKey)
    return value ?? false
  }

  private static func markMigrationComplete(storage: MmkvStorage) async {
    await storage.set(migrationFlagKey, true)
    await storage.synchronize()
    ClixLogger.debug("Marked app group migration as complete")
  }
}
