/// One to 25 distinct nutrient numbers, in the order given, for the `nutrients` filter.
///
/// The FoodData Central specification limits a food lookup to 25 nutrient numbers. Recorded
/// lookups confirm the filter keeps only the nutrients whose legacy numbers it lists, but the limit,
/// and what the service returns for a food with none of the requested nutrients, have not been
/// recorded. The numbers are sent
/// in the order given; nothing is sorted, removed, or split across requests.
///
/// ```swift
/// let macros = try NutrientNumbers([203, 204, 205])
/// let endpoint = Endpoint<Food>.food(2_346_404, nutrients: macros)
/// ```
public struct NutrientNumbers: Hashable, Sendable {
  /// The largest number of nutrient numbers FoodData Central accepts on one request.
  public static let maximumCount = 25

  /// The nutrient numbers, in the order given.
  public let numbers: [NutrientNumber]

  /// Creates a validated list of nutrient numbers.
  /// - Parameter numbers: One to ``maximumCount`` distinct nutrient numbers.
  /// - Throws: ``FoodDataCentralValidationError/nutrientNumberCount(_:)`` for an empty list or one
  ///   longer than ``maximumCount``, and
  ///   ``FoodDataCentralValidationError/duplicateNutrientNumber(_:)`` naming the first repeated
  ///   number.
  public init(_ numbers: [NutrientNumber]) throws(FoodDataCentralValidationError) {
    guard (1...Self.maximumCount).contains(numbers.count) else {
      throw .nutrientNumberCount(numbers.count)
    }
    var seen: Set<NutrientNumber> = []
    for number in numbers where !seen.insert(number).inserted {
      throw .duplicateNutrientNumber(number)
    }
    self.numbers = numbers
  }

  // The comma-separated form the `nutrients` query parameter takes.
  var queryValue: String {
    numbers.map { String($0.rawValue) }.joined(separator: ",")
  }
}
