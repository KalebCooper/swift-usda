/// A nutrient number, the identifier the `nutrients` filter on food lookups matches.
///
/// These are the legacy Standard Reference numbers, such as 203 for protein and 204 for total fat,
/// not the newer nutrient IDs such as 1003: a recorded lookup filtered on `203,204,205` returned
/// exactly the nutrients with those numbers (IDs 1003, 1004, and 1005). Response bodies carry the legacy numbers as strings, in
/// ``AbridgedFoodNutrient/number`` and ``Nutrient/number``. The type checks no range; FoodData
/// Central decides which numbers it knows.
///
/// ```swift
/// let protein: NutrientNumber = 203
/// print(protein.rawValue)  // 203
/// ```
public struct NutrientNumber: ExpressibleByIntegerLiteral, Hashable, Sendable {
  /// The nutrient number.
  public let rawValue: Int

  /// Creates a nutrient number.
  /// - Parameter rawValue: The legacy nutrient number, such as 203.
  public init(_ rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Creates a nutrient number from an integer literal.
  /// - Parameter value: The legacy nutrient number, such as 203.
  public init(integerLiteral value: Int) {
    self.init(value)
  }
}
