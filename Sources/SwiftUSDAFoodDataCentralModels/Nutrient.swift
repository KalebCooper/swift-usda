/// A nutrient's identity: its ID, legacy number, name, and unit, plus its label display hints.
///
/// The display hints ``indentLevel``, ``isNutrientLabel``, ``numberOfDecimals``, and
/// ``shortestName`` arrive only on some nutrients, such as group headings like Proximates.
///
/// ```swift
/// print(nutrient.number, nutrient.name, nutrient.unitName)
/// // Optional("203") Optional("Protein") Optional("g")
/// ```
public struct Nutrient: Codable, Hashable, Sendable {
  /// The nutrient ID, such as 1003 for protein.
  public var id: Int?
  /// The nutrient's indentation depth in a nutrition label.
  public var indentLevel: Int?
  /// Whether the nutrient is a nutrition label entry.
  public var isNutrientLabel: Bool?
  /// The nutrient's name.
  public var name: String?
  /// The legacy nutrient number as a string, such as `203`.
  public var number: String?
  /// The number of decimals the provider displays the nutrient with.
  public var numberOfDecimals: Int?
  /// The nutrient's position in the provider's display order.
  public var rank: Int?
  /// The nutrient's shortest display name.
  public var shortestName: String?
  /// The unit amounts are given in, exactly as sent.
  public var unitName: String?

  /// Creates a nutrient.
  /// - Parameters:
  ///   - id: The nutrient ID.
  ///   - indentLevel: The nutrient's indentation depth in a nutrition label.
  ///   - isNutrientLabel: Whether the nutrient is a nutrition label entry.
  ///   - name: The nutrient's name.
  ///   - number: The legacy nutrient number.
  ///   - numberOfDecimals: The number of decimals the provider displays.
  ///   - rank: The nutrient's position in the provider's display order.
  ///   - shortestName: The nutrient's shortest display name.
  ///   - unitName: The unit amounts are given in.
  public init(
    id: Int? = nil,
    indentLevel: Int? = nil,
    isNutrientLabel: Bool? = nil,
    name: String? = nil,
    number: String? = nil,
    numberOfDecimals: Int? = nil,
    rank: Int? = nil,
    shortestName: String? = nil,
    unitName: String? = nil
  ) {
    self.id = id
    self.indentLevel = indentLevel
    self.isNutrientLabel = isNutrientLabel
    self.name = name
    self.number = number
    self.numberOfDecimals = numberOfDecimals
    self.rank = rank
    self.shortestName = shortestName
    self.unitName = unitName
  }
}
