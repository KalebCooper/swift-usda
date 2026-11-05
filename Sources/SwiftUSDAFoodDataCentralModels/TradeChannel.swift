/// A channel a Branded food is sold through, as FoodData Central names it in a search filter.
///
/// The type is open so a channel the service adds can be sent without a new type. The constants are
/// the eight values the FoodData Central specification (version 1.0.1) lists for the search body's
/// `tradeChannel` filter. The filter comes from the specification and has not been verified
/// against the service.
///
/// ```swift
/// let query = try FoodSearchQuery("apple juice", tradeChannels: [.grocery, .foodService])
/// ```
public struct TradeChannel: Codable, Hashable, RawRepresentable, Sendable {
  /// Child nutrition food programs, `CHILD_NUTRITION_FOOD_PROGRAMS`.
  public static let childNutritionFoodPrograms = TradeChannel(
    rawValue: "CHILD_NUTRITION_FOOD_PROGRAMS")
  /// Drug stores, `DRUG`.
  public static let drug = TradeChannel(rawValue: "DRUG")
  /// Food service, `FOOD_SERVICE`.
  public static let foodService = TradeChannel(rawValue: "FOOD_SERVICE")
  /// Grocery, `GROCERY`.
  public static let grocery = TradeChannel(rawValue: "GROCERY")
  /// Mass merchandising, `MASS_MERCHANDISING`.
  public static let massMerchandising = TradeChannel(rawValue: "MASS_MERCHANDISING")
  /// Military, `MILITARY`.
  public static let military = TradeChannel(rawValue: "MILITARY")
  /// Online, `ONLINE`.
  public static let online = TradeChannel(rawValue: "ONLINE")
  /// Vending, `VENDING`.
  public static let vending = TradeChannel(rawValue: "VENDING")

  /// The channel exactly as FoodData Central spells it.
  public let rawValue: String

  /// Creates a trade channel from its wire spelling.
  /// - Parameter rawValue: The channel name, such as `GROCERY`.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }

  /// Decodes a trade channel from a bare JSON string.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when the value is not a string.
  public init(from decoder: any Decoder) throws {
    self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
  }

  /// Encodes the trade channel as a bare JSON string.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(rawValue)
  }
}
