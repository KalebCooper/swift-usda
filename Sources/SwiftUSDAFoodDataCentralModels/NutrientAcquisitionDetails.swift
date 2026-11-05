/// Where and when a sample used in a nutrient analysis was bought.
///
/// ```swift
/// print(details.storeCity, details.storeState, details.purchaseDate)
/// ```
public struct NutrientAcquisitionDetails: Codable, Hashable, Sendable {
  /// The purchase date as FoodData Central formats it.
  public var purchaseDate: String?
  /// The sample unit's identifier.
  public var sampleUnitID: Int?
  /// The city of the store.
  public var storeCity: String?
  /// The state of the store.
  public var storeState: String?

  /// Creates acquisition details.
  /// - Parameters:
  ///   - purchaseDate: The purchase date.
  ///   - sampleUnitID: The sample unit's identifier.
  ///   - storeCity: The city of the store.
  ///   - storeState: The state of the store.
  public init(
    purchaseDate: String? = nil,
    sampleUnitID: Int? = nil,
    storeCity: String? = nil,
    storeState: String? = nil
  ) {
    self.purchaseDate = purchaseDate
    self.sampleUnitID = sampleUnitID
    self.storeCity = storeCity
    self.storeState = storeState
  }

  enum CodingKeys: String, CodingKey {
    case purchaseDate
    case sampleUnitID = "sampleUnitId"
    case storeCity
    case storeState
  }
}
