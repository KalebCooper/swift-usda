/// A value rejected before any request is described, because it breaks a documented FoodData
/// Central limit.
///
/// ```swift
/// do {
///   _ = try NutrientNumbers([])
/// } catch {
///   print(error)  // nutrientNumberCount(0)
/// }
/// ```
public enum FoodDataCentralValidationError: Error, Hashable, Sendable {
  /// A nutrient number appeared more than once; the associated value is the first repeat.
  case duplicateNutrientNumber(NutrientNumber)
  /// A nutrient list was empty or longer than ``NutrientNumbers/maximumCount``; the associated
  /// value is the count given.
  case nutrientNumberCount(Int)
}
