/// The nutrient retention factor applied to a Survey (FNDDS) input food for its preparation, such
/// as sauteed root vegetables.
///
/// ```swift
/// print(input.retentionFactor?.description ?? "")
/// ```
public struct InputFoodRetentionFactor: Codable, Hashable, Sendable {
  /// The retention factor's code.
  public var code: Int?
  /// The preparation the factor applies to, exactly as sent.
  public var description: String?
  /// The retention factor's identifier.
  public var id: Int?

  /// Creates a retention factor.
  /// - Parameters:
  ///   - code: The retention factor's code.
  ///   - description: The preparation the factor applies to.
  ///   - id: The retention factor's identifier.
  public init(code: Int? = nil, description: String? = nil, id: Int? = nil) {
    self.code = code
    self.description = description
    self.id = id
  }
}
