/// The source category of a nutrient derivation.
///
/// ```swift
/// print(derivation.foodNutrientSource?.description)
/// ```
public struct FoodNutrientSource: Codable, Hashable, Sendable {
  /// The source code.
  public var code: String?
  /// The source's description.
  public var description: String?
  /// The source's identifier.
  public var id: Int?

  /// Creates a source.
  /// - Parameters:
  ///   - code: The source code.
  ///   - description: The source's description.
  ///   - id: The source's identifier.
  public init(code: String? = nil, description: String? = nil, id: Int? = nil) {
    self.code = code
    self.description = description
    self.id = id
  }
}
