/// A household portion of a food and its weight in grams.
///
/// ```swift
/// for portion in food.foodPortions ?? [] {
///   print(portion.amount, portion.measureUnit?.name, portion.gramWeight)
/// }
/// ```
public struct FoodPortion: Codable, Hashable, Sendable {
  /// The number of measure units in the portion.
  public var amount: Double?
  /// The number of observations the weight rests on.
  public var dataPoints: Int?
  /// The portion's weight in grams.
  public var gramWeight: Double?
  /// The portion's identifier.
  public var id: Int?
  /// The unit ``amount`` is counted in.
  public var measureUnit: MeasureUnit?
  /// The earliest year a sample was acquired.
  public var minYearAcquired: Int?
  /// Text qualifying the measure, exactly as sent.
  public var modifier: String?
  /// The portion's description, exactly as sent.
  public var portionDescription: String?
  /// The portion's position in the provider's ordering.
  public var sequenceNumber: Int?

  /// Creates a portion.
  /// - Parameters:
  ///   - amount: The number of measure units in the portion.
  ///   - dataPoints: The number of observations the weight rests on.
  ///   - gramWeight: The portion's weight in grams.
  ///   - id: The portion's identifier.
  ///   - measureUnit: The unit `amount` is counted in.
  ///   - minYearAcquired: The earliest year a sample was acquired.
  ///   - modifier: Text qualifying the measure.
  ///   - portionDescription: The portion's description.
  ///   - sequenceNumber: The portion's position in the provider's ordering.
  public init(
    amount: Double? = nil,
    dataPoints: Int? = nil,
    gramWeight: Double? = nil,
    id: Int? = nil,
    measureUnit: MeasureUnit? = nil,
    minYearAcquired: Int? = nil,
    modifier: String? = nil,
    portionDescription: String? = nil,
    sequenceNumber: Int? = nil
  ) {
    self.amount = amount
    self.dataPoints = dataPoints
    self.gramWeight = gramWeight
    self.id = id
    self.measureUnit = measureUnit
    self.minYearAcquired = minYearAcquired
    self.modifier = modifier
    self.portionDescription = portionDescription
    self.sequenceNumber = sequenceNumber
  }
}
