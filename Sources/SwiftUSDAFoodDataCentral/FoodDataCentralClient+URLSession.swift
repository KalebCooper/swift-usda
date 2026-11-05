#if canImport(Darwin)
import Foundation
import HTTPURLSession

extension FoodDataCentralClient {
  /// Creates a client using the shared URL session and a required data.gov API key.
  /// - Parameter apiKey: The key to send in the `X-Api-Key` header.
  /// - Throws: ``FoodDataCentralError/invalidAPIKey`` for invalid local credential syntax.
  public init(apiKey: String) throws(FoodDataCentralError) {
    self.init(configuration: try FoodDataCentralConfiguration(apiKey: apiKey))
  }

  /// Creates a client using an Apple URL session.
  /// - Parameters:
  ///   - configuration: Required API-key configuration.
  ///   - session: The session used for requests; defaults to the shared session.
  public init(configuration: FoodDataCentralConfiguration, session: URLSession = .shared) {
    self.init(configuration: configuration, transport: URLSessionTransport(session: session))
  }
}
#endif
