/// A sample food record that a Foundation food was derived from.
///
/// ```swift
/// print(input.inputFood?.description, input.inputFood?.foodGroup?.description)
/// ```
public struct SampleFood: Codable, Hashable, Sendable {
  /// The sample's data type, such as `Sample`.
  public var dataType: FoodDataType?
  /// The sample's description.
  public var description: String
  /// The sample's FoodData Central identifier.
  public var fdcID: FoodID
  /// The record class exactly as sent.
  public var foodClass: String?
  /// The food group the sample is filed under.
  public var foodGroup: FoodCategory?
  /// The publication date as FoodData Central formats it.
  public var publicationDate: String?
  /// The sample's total refuse, exactly as sent.
  public var totalRefuse: Double?

  /// Creates a sample food.
  /// - Parameters:
  ///   - dataType: The sample's data type.
  ///   - description: The sample's description.
  ///   - fdcID: The sample's FoodData Central identifier.
  ///   - foodClass: The record class.
  ///   - foodGroup: The food group the sample is filed under.
  ///   - publicationDate: The publication date.
  ///   - totalRefuse: The sample's total refuse.
  public init(
    dataType: FoodDataType? = nil,
    description: String,
    fdcID: FoodID,
    foodClass: String? = nil,
    foodGroup: FoodCategory? = nil,
    publicationDate: String? = nil,
    totalRefuse: Double? = nil
  ) {
    self.dataType = dataType
    self.description = description
    self.fdcID = fdcID
    self.foodClass = foodClass
    self.foodGroup = foodGroup
    self.publicationDate = publicationDate
    self.totalRefuse = totalRefuse
  }

  enum CodingKeys: String, CodingKey {
    case dataType
    case description
    case fdcID = "fdcId"
    case foodClass
    case foodGroup
    case publicationDate
    case totalRefuse
  }
}
