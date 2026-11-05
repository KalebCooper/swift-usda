/// How a nutrient amount was obtained, such as analytically or by calculation.
///
/// ```swift
/// print(nutrient.foodNutrientDerivation?.code)  // Optional("A")
/// ```
public struct FoodNutrientDerivation: Codable, Hashable, Sendable {
  /// The derivation code, such as `A`.
  public var code: String?
  /// The derivation's description, such as `Analytical`.
  public var description: String?
  /// The source the derivation belongs to.
  public var foodNutrientSource: FoodNutrientSource?
  /// The derivation's identifier.
  public var id: Int?

  /// Creates a derivation.
  /// - Parameters:
  ///   - code: The derivation code.
  ///   - description: The derivation's description.
  ///   - foodNutrientSource: The source the derivation belongs to.
  ///   - id: The derivation's identifier.
  public init(
    code: String? = nil,
    description: String? = nil,
    foodNutrientSource: FoodNutrientSource? = nil,
    id: Int? = nil
  ) {
    self.code = code
    self.description = description
    self.foodNutrientSource = foodNutrientSource
    self.id = id
  }
}
