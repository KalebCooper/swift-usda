/// A food in FoodData Central's abridged format: identity, data type, and nutrient amounts only.
///
/// The abridged format has one shape for every data type. Fields that apply to one data type, such
/// as ``brandOwner`` for Branded foods or ``foodCode`` for Survey foods, are `nil` for the others.
/// Dates and codes are kept as the provider's strings.
///
/// ```swift
/// let food = try JSONDecoder().decode(AbridgedFood.self, from: body)
/// for nutrient in food.foodNutrients {
///   print(nutrient.name, nutrient.amount ?? 0, nutrient.unitName)
/// }
/// ```
public struct AbridgedFood: Codable, Hashable, Sendable {
  /// The brand owner, for Branded foods.
  public var brandOwner: String?
  /// The data type the food belongs to.
  public var dataType: FoodDataType
  /// The food's description, exactly as published, including any leading or trailing spaces.
  public var description: String
  /// The food's FoodData Central identifier.
  public var fdcID: FoodID
  /// The FNDDS food code, for Survey foods.
  public var foodCode: String?
  /// The food's nutrients, in the provider's order; empty when a nutrient filter matched none.
  public var foodNutrients: [AbridgedFoodNutrient]
  /// The GTIN or UPC barcode, for Branded foods, kept as a string with its leading zeros.
  public var gtinUpc: String?
  /// The legacy NDB number, for Foundation and SR Legacy foods.
  public var ndbNumber: String?
  /// The publication date as FoodData Central formats it, such as `2019-04-01`.
  public var publicationDate: String?

  /// Creates an abridged food.
  /// - Parameters:
  ///   - brandOwner: The brand owner, for Branded foods.
  ///   - dataType: The data type the food belongs to.
  ///   - description: The food's description.
  ///   - fdcID: The food's FoodData Central identifier.
  ///   - foodCode: The FNDDS food code, for Survey foods.
  ///   - foodNutrients: The food's nutrients.
  ///   - gtinUpc: The GTIN or UPC barcode, for Branded foods.
  ///   - ndbNumber: The legacy NDB number, for Foundation and SR Legacy foods.
  ///   - publicationDate: The publication date.
  public init(
    brandOwner: String? = nil,
    dataType: FoodDataType,
    description: String,
    fdcID: FoodID,
    foodCode: String? = nil,
    foodNutrients: [AbridgedFoodNutrient],
    gtinUpc: String? = nil,
    ndbNumber: String? = nil,
    publicationDate: String? = nil
  ) {
    self.brandOwner = brandOwner
    self.dataType = dataType
    self.description = description
    self.fdcID = fdcID
    self.foodCode = foodCode
    self.foodNutrients = foodNutrients
    self.gtinUpc = gtinUpc
    self.ndbNumber = ndbNumber
    self.publicationDate = publicationDate
  }

  enum CodingKeys: String, CodingKey {
    case brandOwner
    case dataType
    case description
    case fdcID = "fdcId"
    case foodCode
    case foodNutrients
    case gtinUpc
    case ndbNumber
    case publicationDate
  }
}
