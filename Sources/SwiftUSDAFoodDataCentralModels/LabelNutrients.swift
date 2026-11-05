/// The nutrient values printed on a Branded food's label, per serving.
///
/// Each value is the label's own figure in the label's units; nothing is converted or recomputed
/// from ``BrandedFood/foodNutrients``. A nutrient the label omits is `nil`.
///
/// ```swift
/// print(food.labelNutrients?.protein?.value ?? 0)
/// ```
public struct LabelNutrients: Codable, Hashable, Sendable {
  /// One nutrient value as printed on the label.
  ///
  /// ```swift
  /// let fat = LabelNutrients.Value(value: 8.9992)
  /// ```
  public struct Value: Codable, Hashable, Sendable {
    /// The printed value.
    public var value: Double?

    /// Creates a label value.
    /// - Parameter value: The printed value.
    public init(value: Double?) {
      self.value = value
    }
  }

  /// Calcium.
  public var calcium: Value?
  /// Calories.
  public var calories: Value?
  /// Total carbohydrates.
  public var carbohydrates: Value?
  /// Cholesterol.
  public var cholesterol: Value?
  /// Total fat.
  public var fat: Value?
  /// Dietary fiber.
  public var fiber: Value?
  /// Iron.
  public var iron: Value?
  /// Potassium.
  public var potassium: Value?
  /// Protein.
  public var protein: Value?
  /// Saturated fat.
  public var saturatedFat: Value?
  /// Sodium.
  public var sodium: Value?
  /// Total sugars.
  public var sugars: Value?
  /// Trans fat.
  public var transFat: Value?

  /// Creates label nutrients.
  /// - Parameters:
  ///   - calcium: Calcium.
  ///   - calories: Calories.
  ///   - carbohydrates: Total carbohydrates.
  ///   - cholesterol: Cholesterol.
  ///   - fat: Total fat.
  ///   - fiber: Dietary fiber.
  ///   - iron: Iron.
  ///   - potassium: Potassium.
  ///   - protein: Protein.
  ///   - saturatedFat: Saturated fat.
  ///   - sodium: Sodium.
  ///   - sugars: Total sugars.
  ///   - transFat: Trans fat.
  public init(
    calcium: Value? = nil,
    calories: Value? = nil,
    carbohydrates: Value? = nil,
    cholesterol: Value? = nil,
    fat: Value? = nil,
    fiber: Value? = nil,
    iron: Value? = nil,
    potassium: Value? = nil,
    protein: Value? = nil,
    saturatedFat: Value? = nil,
    sodium: Value? = nil,
    sugars: Value? = nil,
    transFat: Value? = nil
  ) {
    self.calcium = calcium
    self.calories = calories
    self.carbohydrates = carbohydrates
    self.cholesterol = cholesterol
    self.fat = fat
    self.fiber = fiber
    self.iron = iron
    self.potassium = potassium
    self.protein = protein
    self.saturatedFat = saturatedFat
    self.sodium = sodium
    self.sugars = sugars
    self.transFat = transFat
  }
}
