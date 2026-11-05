/// One nutrient amount in an abridged food.
///
/// ```swift
/// let protein = food.foodNutrients.first { $0.number == "203" }
/// print(protein?.amount, protein?.unitName)  // Optional(21.2) Optional("G")
/// ```
public struct AbridgedFoodNutrient: Codable, Hashable, Sendable {
  /// The amount per 100 g or 100 ml, in ``unitName``; `nil` when the provider sends none.
  public var amount: Double?
  /// The code for how the amount was derived, such as `A` for analytical; absent for Survey foods.
  public var derivationCode: String?
  /// The description of ``derivationCode``.
  public var derivationDescription: String?
  /// The nutrient's name, such as `Protein`.
  public var name: String
  /// The legacy nutrient number as a string, such as `203`.
  public var number: String
  /// The unit of ``amount`` exactly as sent, such as `G`, `MG`, `IU`, or `kJ`.
  public var unitName: String

  /// Creates an abridged nutrient.
  /// - Parameters:
  ///   - amount: The amount per 100 g or 100 ml.
  ///   - derivationCode: The code for how the amount was derived.
  ///   - derivationDescription: The description of `derivationCode`.
  ///   - name: The nutrient's name.
  ///   - number: The legacy nutrient number.
  ///   - unitName: The unit of `amount`.
  public init(
    amount: Double? = nil,
    derivationCode: String? = nil,
    derivationDescription: String? = nil,
    name: String,
    number: String,
    unitName: String
  ) {
    self.amount = amount
    self.derivationCode = derivationCode
    self.derivationDescription = derivationDescription
    self.name = name
    self.number = number
    self.unitName = unitName
  }
}
