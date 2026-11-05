/// Required credentials for requests to the FoodData Central API.
///
/// Supply a data.gov API key. There is no default key and the library never reads the
/// environment. Store credentials outside source control and application bundles: data.gov
/// deactivates keys it finds in public repositories.
///
/// ```swift
/// let configuration = try FoodDataCentralConfiguration(apiKey: apiKey)
/// ```
public struct FoodDataCentralConfiguration: CustomDebugStringConvertible,
  CustomStringConvertible, Sendable
{
  /// A redacted representation suitable for debugging.
  public var debugDescription: String { description }

  /// A representation that omits the API key.
  public var description: String { "FoodDataCentralConfiguration(apiKey: <redacted>)" }

  let apiKey: String

  /// Validates and stores the credential without contacting FoodData Central.
  ///
  /// Local validation rejects empty values, whitespace, and non-ASCII header characters. The
  /// gateway remains responsible for deciding whether a key is valid, and reports a rejected key
  /// as ``FoodDataCentralError/gateway(_:response:)``.
  /// - Parameter apiKey: The exact data.gov key to send in `X-Api-Key`, without normalization.
  /// - Throws: ``FoodDataCentralError/invalidAPIKey`` when the key cannot be safely sent.
  public init(apiKey: String) throws(FoodDataCentralError) {
    guard !apiKey.isEmpty, apiKey.utf8.allSatisfy({ (33...126).contains($0) }) else {
      throw .invalidAPIKey
    }
    self.apiKey = apiKey
  }
}
