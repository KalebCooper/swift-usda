/// An attribute of a food, such as a common name, a taxon link, or a moisture adjustment.
///
/// FoodData Central sends ``value`` as a JSON string for most attributes and as a JSON integer for
/// some Branded ones. Both decode into the one string, and encoding writes it back as a string.
///
/// ```swift
/// for attribute in food.foodAttributes ?? [] {
///   print(attribute.foodAttributeType?.name ?? "", attribute.value ?? "")
/// }
/// ```
public struct FoodAttribute: Codable, Hashable, Sendable {
  /// The kind of attribute.
  public var foodAttributeType: FoodAttributeType?
  /// The attribute's identifier.
  public var id: Int?
  /// The attribute's name, such as `NCBI Taxon`, when the provider sends one.
  public var name: String?
  /// The attribute's position among the food's attributes.
  public var sequenceNumber: Int?
  /// The attribute's value as a string, such as `Moisture change: -5.0%`; an integer the provider
  /// sends is kept as its decimal digits.
  public var value: String?

  /// Creates an attribute.
  /// - Parameters:
  ///   - foodAttributeType: The kind of attribute.
  ///   - id: The attribute's identifier.
  ///   - name: The attribute's name.
  ///   - sequenceNumber: The attribute's position among the food's attributes.
  ///   - value: The attribute's value.
  public init(
    foodAttributeType: FoodAttributeType? = nil,
    id: Int? = nil,
    name: String? = nil,
    sequenceNumber: Int? = nil,
    value: String? = nil
  ) {
    self.foodAttributeType = foodAttributeType
    self.id = id
    self.name = name
    self.sequenceNumber = sequenceNumber
    self.value = value
  }

  /// Decodes an attribute, accepting a string or an integer ``value``.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when a field has another shape.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    foodAttributeType = try container.decodeIfPresent(
      FoodAttributeType.self, forKey: .foodAttributeType)
    id = try container.decodeIfPresent(Int.self, forKey: .id)
    name = try container.decodeIfPresent(String.self, forKey: .name)
    sequenceNumber = try container.decodeIfPresent(Int.self, forKey: .sequenceNumber)
    value = try container.decodeIntegerOrStringIfPresent(forKey: .value)
  }

  enum CodingKeys: String, CodingKey {
    case foodAttributeType
    case id
    case name
    case sequenceNumber
    case value
  }
}
