import Foundation
import MMKV

struct StorageMigrator {
  // IMPORTANT: When adding new storage keys, update this list to ensure proper migration
  // 1. Add new key constant to the service that uses it
  // 2. Add the key string to this array
  // 3. Run tests to verify migration
  static let knownStorageKeys = [
    "clix_config",
    "clix_device_id",
    "clix_current_push_token",
    "clix_push_tokens",
    "clix_notification_settings",
    "clix_last_received_message_id"
  ]

  static func migrateKeys<Source, Destination>(
    from source: Source,
    to destination: Destination,
    keys: [String],
    sourceName: String,
    destinationName: String,
    removeFromSource: Bool = false,
    getDataFrom: (Source, String) -> Data?,
    setDataTo: (Destination, String, Data) -> Void,
    removeFrom: ((Source, String) -> Void)? = nil,
    syncSource: ((Source) -> Void)? = nil,
    syncDestination: ((Destination) -> Void)? = nil
  ) -> Int {
    var migratedCount = 0

    for key in keys {
      if let data = getDataFrom(source, key) {
        setDataTo(destination, key, data)

        if removeFromSource, let removeFrom = removeFrom {
          removeFrom(source, key)
        }

        migratedCount += 1
        ClixLogger.debug("Migrated key: \(key)")
      }
    }

    syncSource?(source)
    syncDestination?(destination)

    ClixLogger.info("Migrated \(migratedCount) keys from \(sourceName) to \(destinationName)")
    return migratedCount
  }

  static func migrateMmkvToMmkv(
    from sourceMmkv: MMKV,
    to destinationMmkv: MMKV,
    keys: [String]
  ) -> Int {
    migrateKeys(
      from: sourceMmkv,
      to: destinationMmkv,
      keys: keys,
      sourceName: "source MMKV",
      destinationName: "destination MMKV",
      removeFromSource: false,
      getDataFrom: { mmkv, key in mmkv.data(forKey: key) },
      setDataTo: { mmkv, key, data in mmkv.set(data, forKey: key) },
      syncSource: { $0.sync() },
      syncDestination: { $0.sync() }
    )
  }

  static func migrateUserDefaultsToUserDefaults(
    from sourceDefaults: UserDefaults,
    to destinationDefaults: UserDefaults,
    keys: [String]
  ) -> Int {
    migrateKeys(
      from: sourceDefaults,
      to: destinationDefaults,
      keys: keys,
      sourceName: "source UserDefaults",
      destinationName: "destination UserDefaults",
      removeFromSource: false,
      getDataFrom: { defaults, key in defaults.data(forKey: key) },
      setDataTo: { defaults, key, data in defaults.set(data, forKey: key) },
      syncSource: { _ in },
      syncDestination: { _ in }
    )
  }
}
