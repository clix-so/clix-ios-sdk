import ActivityKit
import Foundation

@available(iOS 16.1, *)
@available(iOSApplicationExtension, unavailable)
public class ClixLiveActivity {
  public static let shared = ClixLiveActivity()

  private let service = LiveActivityService()

  private init() {}

  /// Starts listening for push-to-start tokens. Requires iOS 17.2+ (checked internally).
  public func setup<Attributes: ActivityAttributes>(_ activityType: Attributes.Type) {
    Task {
      await service.startListeningForPushToStartToken(activityType)
    }
  }
}
