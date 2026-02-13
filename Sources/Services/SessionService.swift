import Foundation
#if !APPLICATION_EXTENSION_API_ONLY
  import UIKit
#endif

enum SessionEvent: String {
  case sessionStart = "SESSION_START"
}

class SessionService {
  private static let lastActivityKey = "clix_session_last_activity"

  private let storageService: StorageService
  private let eventService: EventService
  private let sessionTimeoutMs: Int
  private var pendingMessageId: String?

  init(storageService: StorageService, eventService: EventService, sessionTimeoutMs: Int) {
    self.storageService = storageService
    self.eventService = eventService
    self.sessionTimeoutMs = max(sessionTimeoutMs, 5000)
  }

  func start() async {
    let lastActivity: Double? = await storageService.get(Self.lastActivityKey)
    if let lastActivity {
      let elapsed = Date().timeIntervalSince1970 * 1000 - lastActivity
      if elapsed <= Double(sessionTimeoutMs) {
        pendingMessageId = nil
        await updateLastActivity()
        ClixLogger.debug("Continuing existing session")
        return
      }
    }
    await startNewSession()
  }

  #if !APPLICATION_EXTENSION_API_ONLY
    func setupLifecycleObservers() {
      NotificationCenter.default.addObserver(
        forName: UIApplication.willEnterForegroundNotification,
        object: nil, queue: .main
      ) { [weak self] _ in
        Task { await self?.handleForeground() }
      }
      NotificationCenter.default.addObserver(
        forName: UIApplication.didEnterBackgroundNotification,
        object: nil, queue: .main
      ) { [weak self] _ in
        Task { await self?.updateLastActivity() }
      }
    }
  #endif

  func setPendingMessageId(_ messageId: String?) {
    pendingMessageId = messageId
  }

  // MARK: - Private

  private func handleForeground() async {
    let lastActivity: Double? = await storageService.get(Self.lastActivityKey)
    if let lastActivity {
      let elapsed = Date().timeIntervalSince1970 * 1000 - lastActivity
      if elapsed <= Double(sessionTimeoutMs) {
        pendingMessageId = nil
        await updateLastActivity()
        return
      }
    }
    await startNewSession()
  }

  private func startNewSession() async {
    let messageId = pendingMessageId
    pendingMessageId = nil
    await updateLastActivity()

    do {
      try await eventService.trackEvent(
        name: SessionEvent.sessionStart.rawValue,
        messageId: messageId
      )
      ClixLogger.debug("\(SessionEvent.sessionStart.rawValue) tracked")
    } catch {
      ClixLogger.error("Failed to track \(SessionEvent.sessionStart.rawValue): \(error)")
    }
  }

  private func updateLastActivity() async {
    await storageService.set(Self.lastActivityKey, Date().timeIntervalSince1970 * 1000)
  }
}
