/// The error body returned by the api.data.gov gateway in front of FoodData Central.
///
/// The gateway answers credential and rate-limit failures with this body before a request reaches
/// FoodData Central, for example `403` with `API_KEY_MISSING` or `API_KEY_INVALID`, and `429` with
/// `OVER_RATE_LIMIT`. Codes are open strings, including values introduced after this package was
/// compiled.
///
/// ```swift
/// let response = try JSONDecoder().decode(DataGovErrorResponse.self, from: body)
/// print(response.error.code)  // "API_KEY_MISSING"
/// ```
public struct DataGovErrorResponse: Codable, Hashable, Sendable {
  /// The gateway's explanation of a failed request.
  public struct Detail: Codable, Hashable, Sendable {
    /// The gateway code, such as `API_KEY_MISSING` or `OVER_RATE_LIMIT`.
    public let code: String

    /// The gateway's original explanatory text.
    public let message: String

    /// Creates a detail from a code and its message.
    /// - Parameters:
    ///   - code: The gateway code.
    ///   - message: The explanatory text.
    public init(code: String, message: String) {
      self.code = code
      self.message = message
    }
  }

  /// The error reported by the gateway.
  public let error: Detail

  /// Creates a response from its detail.
  /// - Parameter error: The error reported by the gateway.
  public init(error: Detail) {
    self.error = error
  }
}
