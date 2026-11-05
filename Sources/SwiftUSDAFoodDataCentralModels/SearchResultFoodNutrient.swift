/// One nutrient amount in a food search result.
///
/// Two spellings of these fields exist and neither has been verified against a recorded response.
/// The FoodData Central specification (version 1.0.1) lists `amount`, `name`, and `number`; the
/// service is understood to send `value`, `nutrientName`, `nutrientNumber`, and `nutrientId`
/// instead. Decoding accepts both, reading the service's spelling first and the specification's
/// second, so a nutrient that carries both keeps the service's values. Encoding always writes the
/// service's spelling (`value`, `nutrientName`, `nutrientNumber`, `nutrientId`), so a decoded
/// nutrient survives a round trip unchanged. Every field is optional, and keys neither spelling
/// names are not kept.
///
/// ```swift
/// let protein = food.foodNutrients?.first { $0.number == "203" }
/// print(protein?.amount ?? 0, protein?.unitName ?? "")
/// ```
public struct SearchResultFoodNutrient: Codable, Hashable, Sendable {
  /// The amount, in ``unitName``, from `value` or `amount`.
  public var amount: Double?
  /// The code for how the amount was derived.
  public var derivationCode: String?
  /// The description of ``derivationCode``.
  public var derivationDescription: String?
  /// The nutrient's name, such as `Iron, Fe`, from `nutrientName` or `name`.
  public var name: String?
  /// The nutrient's FoodData Central identifier, such as `1089`, from `nutrientId`; the
  /// specification's spelling has no counterpart.
  public var nutrientID: Int?
  /// The legacy nutrient number, such as `303`, from `nutrientNumber` or `number`, kept as a
  /// string whether it arrives as a JSON integer or string.
  public var number: String?
  /// The unit of ``amount`` exactly as sent, such as `mg`.
  public var unitName: String?

  /// Creates a search result nutrient.
  /// - Parameters:
  ///   - amount: The amount, in `unitName`.
  ///   - derivationCode: The code for how the amount was derived.
  ///   - derivationDescription: The description of `derivationCode`.
  ///   - name: The nutrient's name.
  ///   - nutrientID: The nutrient's FoodData Central identifier.
  ///   - number: The legacy nutrient number.
  ///   - unitName: The unit of `amount`.
  public init(
    amount: Double? = nil,
    derivationCode: String? = nil,
    derivationDescription: String? = nil,
    name: String? = nil,
    nutrientID: Int? = nil,
    number: String? = nil,
    unitName: String? = nil
  ) {
    self.amount = amount
    self.derivationCode = derivationCode
    self.derivationDescription = derivationDescription
    self.name = name
    self.nutrientID = nutrientID
    self.number = number
    self.unitName = unitName
  }

  /// Decodes a search result nutrient from either spelling, the service's first.
  ///
  /// A string or an integer number is accepted under either `nutrientNumber` or `number`.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when a field has another shape.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    amount =
      try container.decodeIfPresent(Double.self, forKey: .value)
      ?? container.decodeIfPresent(Double.self, forKey: .amount)
    derivationCode = try container.decodeIfPresent(String.self, forKey: .derivationCode)
    derivationDescription = try container.decodeIfPresent(
      String.self, forKey: .derivationDescription)
    name =
      try container.decodeIfPresent(String.self, forKey: .nutrientName)
      ?? container.decodeIfPresent(String.self, forKey: .name)
    nutrientID = try container.decodeIfPresent(Int.self, forKey: .nutrientID)
    number =
      try container.decodeIntegerOrStringIfPresent(forKey: .nutrientNumber)
      ?? container.decodeIntegerOrStringIfPresent(forKey: .number)
    unitName = try container.decodeIfPresent(String.self, forKey: .unitName)
  }

  /// Encodes the nutrient in the service's spelling.
  ///
  /// The amount is written as `value`, the name as `nutrientName`, and the number as the string
  /// `nutrientNumber`; `nil` fields are omitted.
  /// - Parameter encoder: The encoder to write to.
  /// - Throws: An error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(derivationCode, forKey: .derivationCode)
    try container.encodeIfPresent(derivationDescription, forKey: .derivationDescription)
    try container.encodeIfPresent(nutrientID, forKey: .nutrientID)
    try container.encodeIfPresent(name, forKey: .nutrientName)
    try container.encodeIfPresent(number, forKey: .nutrientNumber)
    try container.encodeIfPresent(unitName, forKey: .unitName)
    try container.encodeIfPresent(amount, forKey: .value)
  }

  enum CodingKeys: String, CodingKey {
    case amount
    case derivationCode
    case derivationDescription
    case name
    case nutrientID = "nutrientId"
    case nutrientName
    case nutrientNumber
    case number
    case unitName
    case value
  }
}
