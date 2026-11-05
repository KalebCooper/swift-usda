/// A FoodData Central food identifier, the `fdcId` the provider assigns to every food record.
///
/// The value is the provider's integer exactly as sent. FoodData Central documents no range or
/// format for it, so the type checks none; an identifier the service does not know is answered by
/// the service, not rejected here. It encodes and decodes as a bare JSON integer.
///
/// ```swift
/// let id: FoodID = 2_346_404
/// let same = FoodID(2_346_404)
/// print(id == same, id.rawValue)  // true 2346404
/// ```
public struct FoodID: Codable, ExpressibleByIntegerLiteral, Hashable, Sendable {
  /// The provider's integer identifier.
  public let rawValue: Int

  /// Creates an identifier from the provider's integer.
  /// - Parameter rawValue: The `fdcId` value.
  public init(_ rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Creates an identifier from an integer literal.
  /// - Parameter value: The `fdcId` value.
  public init(integerLiteral value: Int) {
    self.init(value)
  }

  /// Decodes an identifier from a bare JSON integer.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when the value is not an integer.
  public init(from decoder: any Decoder) throws {
    self.init(try decoder.singleValueContainer().decode(Int.self))
  }

  /// Encodes the identifier as a bare JSON integer.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
