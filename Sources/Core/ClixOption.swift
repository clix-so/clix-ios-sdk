import Foundation

/// Structure that manages Clix SDK configuration
public struct ClixConfig {
    /// Logging level setting
    public let loggingLevel: ClixLogLevel

    /// Initialize ClixConfig
    /// - Parameters:
    ///   - loggingLevel: Logging level (default: .info)
    public init(
        loggingLevel: ClixLogLevel = .info
    ) {
        self.loggingLevel = loggingLevel
    }
}
