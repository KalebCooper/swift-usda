/// A sample food a Foundation food's values were derived from.
///
/// ```swift
/// for input in food.inputFoods ?? [] {
///   print(input.foodDescription, input.inputFood?.fdcID)
/// }
/// ```
public struct FoundationInputFood: Codable, Hashable, Sendable {
  /// The input food's description.
  public var foodDescription: String?
  /// The input record's identifier.
  public var id: Int?
  /// The sample food record, when the provider includes it.
  public var inputFood: SampleFood?

  /// Creates a Foundation input food.
  /// - Parameters:
  ///   - foodDescription: The input food's description.
  ///   - id: The input record's identifier.
  ///   - inputFood: The sample food record.
  public init(foodDescription: String? = nil, id: Int? = nil, inputFood: SampleFood? = nil) {
    self.foodDescription = foodDescription
    self.id = id
    self.inputFood = inputFood
  }
}
