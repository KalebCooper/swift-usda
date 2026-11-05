/// One nutrient value in a full food record, with its statistics and derivation.
///
/// Group headings such as Proximates arrive as entries with a ``nutrient`` but no ``id`` or
/// ``amount``.
///
/// ```swift
/// let energy = food.foodNutrients?.first { $0.nutrient?.number == "208" }
/// print(energy?.amount, energy?.nutrient?.unitName)
/// ```
public struct FoodNutrient: Codable, Hashable, Sendable {
  /// The amount per 100 g, in the nutrient's ``Nutrient/unitName``.
  public var amount: Double?
  /// The number of observations the amount rests on.
  public var dataPoints: Int?
  /// How the amount was derived.
  public var foodNutrientDerivation: FoodNutrientDerivation?
  /// The food nutrient record's identifier, which is not the nutrient's own ID; `nil` for group
  /// headings.
  public var id: Int?
  /// The largest observed amount.
  public var max: Double?
  /// The median observed amount.
  public var median: Double?
  /// The smallest observed amount.
  public var min: Double?
  /// The earliest year a sample was acquired.
  public var minYearAcquired: Int?
  /// The nutrient the amount is for.
  public var nutrient: Nutrient?
  /// The laboratory analyses behind the amount, one per analyzed subsample.
  public var nutrientAnalysisDetails: [NutrientAnalysisDetails]?
  /// The record type exactly as sent, such as `FoodNutrient`.
  public var type: String?

  /// Creates a food nutrient.
  /// - Parameters:
  ///   - amount: The amount per 100 g.
  ///   - dataPoints: The number of observations the amount rests on.
  ///   - foodNutrientDerivation: How the amount was derived.
  ///   - id: The food nutrient record's identifier.
  ///   - max: The largest observed amount.
  ///   - median: The median observed amount.
  ///   - min: The smallest observed amount.
  ///   - minYearAcquired: The earliest year a sample was acquired.
  ///   - nutrient: The nutrient the amount is for.
  ///   - nutrientAnalysisDetails: The laboratory analyses behind the amount.
  ///   - type: The record type.
  public init(
    amount: Double? = nil,
    dataPoints: Int? = nil,
    foodNutrientDerivation: FoodNutrientDerivation? = nil,
    id: Int? = nil,
    max: Double? = nil,
    median: Double? = nil,
    min: Double? = nil,
    minYearAcquired: Int? = nil,
    nutrient: Nutrient? = nil,
    nutrientAnalysisDetails: [NutrientAnalysisDetails]? = nil,
    type: String? = nil
  ) {
    self.amount = amount
    self.dataPoints = dataPoints
    self.foodNutrientDerivation = foodNutrientDerivation
    self.id = id
    self.max = max
    self.median = median
    self.min = min
    self.minYearAcquired = minYearAcquired
    self.nutrient = nutrient
    self.nutrientAnalysisDetails = nutrientAnalysisDetails
    self.type = type
  }
}
