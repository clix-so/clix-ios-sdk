import Foundation

struct StorageTypeMigrator {
  static func migrateIfNeeded(
    from source: UserDefaultsStorage,
    to destination: MmkvStorage
  ) async {
    guard await checkIfMigrationNeeded(from: source) else {
      ClixLogger.debug("No UserDefaults data found, skipping migration")
      return
    }

    ClixLogger.info("Migrating data from UserDefaults to MMKV...")
    await migrateData(from: source, to: destination)
    ClixLogger.info("Migration completed successfully")
  }

  private static func checkIfMigrationNeeded(from source: UserDefaultsStorage) async -> Bool {
    for key in StorageMigrator.knownStorageKeys {
      if let _: String = await source.get(key) {
        ClixLogger.debug("Found existing data in UserDefaults for key: \(key) (String)")
        return true
      }
      if let _: [String] = await source.get(key) {
        ClixLogger.debug("Found existing data in UserDefaults for key: \(key) ([String])")
        return true
      }
      if let _: Data = await source.get(key) {
        ClixLogger.debug("Found existing data in UserDefaults for key: \(key) (Data)")
        return true
      }
    }
    return false
  }

  private static func migrateData(from source: UserDefaultsStorage, to destination: MmkvStorage) async {
    var migratedCount = 0

    for key in StorageMigrator.knownStorageKeys {
      if let stringValue: String = await source.get(key) {
        await destination.set(key, stringValue)
        await source.remove(key)
        migratedCount += 1
        ClixLogger.debug("Migrated key: \(key)")
      } else if let arrayValue: [String] = await source.get(key) {
        await destination.set(key, arrayValue)
        await source.remove(key)
        migratedCount += 1
        ClixLogger.debug("Migrated key: \(key)")
      } else if let dataValue: Data = await source.get(key) {
        await destination.set(key, dataValue)
        await source.remove(key)
        migratedCount += 1
        ClixLogger.debug("Migrated key: \(key)")
      }
    }

    await source.synchronize()
    await destination.synchronize()

    ClixLogger.info("Migrated \(migratedCount) keys from UserDefaults to MMKV")
  }
}
