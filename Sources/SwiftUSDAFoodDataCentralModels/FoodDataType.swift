/// A FoodData Central data type, such as Foundation or SR Legacy, as named on the wire.
///
/// The type is open: FoodData Central publishes data types its specification does not list, such
/// as Experimental, so any string decodes and is kept exactly. The constants name the values the
/// specification documents.
///
/// ```swift
/// let type = FoodDataType(rawValue: "Survey (FNDDS)")
/// print(type == .survey)  // true
/// ```
public struct FoodDataType: Codable, Hashable, RawRepresentable, Sendable {
  /// Branded foods, `Branded`.
  public static let branded = FoodDataType(rawValue: "Branded")
  /// Foundation foods, `Foundation`.
  public static let foundation = FoodDataType(rawValue: "Foundation")
  /// Standard Reference legacy foods, `SR Legacy`.
  public static let srLegacy = FoodDataType(rawValue: "SR Legacy")
  /// Food and Nutrient Database for Dietary Studies foods, `Survey (FNDDS)`.
  public static let survey = FoodDataType(rawValue: "Survey (FNDDS)")

  /// The data type exactly as FoodData Central spells it.
  public let rawValue: String

  /// Creates a data type from its wire spelling.
  /// - Parameter rawValue: The data type name, such as `SR Legacy`.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  /// Decodes a data type from a bare JSON string.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when the value is not a string.
  public init(from decoder: any Decoder) throws {
    self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
  }

  /// Encodes the data type as a bare JSON string.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
