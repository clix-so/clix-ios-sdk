import ActivityKit
import Foundation

@available(iOS 16.1, *)
actor LiveActivityService {
  private let apiService = LiveActivityAPIService()
  private var activeListeners: Set<String> = []

  func startListeningForPushToStartToken<Attributes: ActivityAttributes>(
    _ activityType: Attributes.Type
  ) async {
    let activityTypeName = String(describing: Attributes.self)

    guard #available(iOS 17.2, *) else {
      ClixLogger.debug("pushToStartToken listening requires iOS 17.2+")
      return
    }

    guard !activeListeners.contains(activityTypeName) else {
      ClixLogger.debug("Already listening for pushToStartToken: \(activityTypeName)")
      return
    }

    activeListeners.insert(activityTypeName)
    ClixLogger.debug("Starting pushToStartToken listener: \(activityTypeName)")

    Task {
      await listenForPushToStartTokenUpdates(activityType)
    }
  }

  @available(iOS 17.2, *)
  private func listenForPushToStartTokenUpdates<Attributes: ActivityAttributes>(
    _ activityType: Attributes.Type
  ) async {
    let activityTypeName = String(describing: Attributes.self)

    for await tokenData in Activity<Attributes>.pushToStartTokenUpdates {
      let token = tokenData.map { String(format: "%02x", $0) }.joined()
      ClixLogger.debug("Received pushToStartToken for \(activityTypeName): \(token)")
      await sendPushToStartToken(token, activityType: activityTypeName)
    }
  }

  private func sendPushToStartToken(_ token: String, activityType: String) async {
    do {
      await Clix.shared.initCoordinator.waitForInitialization()

      let environment = try Clix.shared.get(\.environment)
      let deviceId = environment.getDevice().id

      try await apiService.registerLiveActivityStartToken(
        deviceId: deviceId,
        activityType: activityType,
        token: token
      )

      ClixLogger.debug("Sent pushToStartToken for \(activityType)")
    } catch {
      ClixLogger.error("Failed to send pushToStartToken for \(activityType): \(error)")
    }
  }
}
