/// A Survey (FNDDS) food in FoodData Central's full format: a food as reported in What We Eat in
/// America, with its nutrients, portions, attributes, and the ingredients its values were computed
/// from.
///
/// Every field but the identity is optional because FoodData Central documents only ``fdcID``,
/// ``dataType``, and ``description`` as always present. Dates and codes are kept as the provider's
/// strings.
///
/// ```swift
/// if case .survey(let food) = try JSONDecoder().decode(Food.self, from: body) {
///   print(food.foodCode ?? "", food.wweiaFoodCategory?.wweiaFoodCategoryDescription ?? "")
/// }
/// ```
public struct SurveyFood: Codable, Hashable, Sendable {
  /// The data type, ``FoodDataType/survey``.
  public var dataType: FoodDataType
  /// The food's description, exactly as published.
  public var description: String
  /// The last date of the survey period, as FoodData Central formats it.
  public var endDate: String?
  /// The food's FoodData Central identifier.
  public var fdcID: FoodID
  /// The food's attributes, such as adjustments made to it.
  public var foodAttributes: [FoodAttribute]?
  /// The record class exactly as sent.
  public var foodClass: String?
  /// The FNDDS food code, such as `27116100`.
  public var foodCode: String?
  /// The food's nutrient values, in the provider's order.
  public var foodNutrients: [FoodNutrient]?
  /// The household portions and their gram weights.
  public var foodPortions: [FoodPortion]?
  /// The ingredients the food's values were computed from.
  public var inputFoods: [InputFood]?
  /// The publication date as FoodData Central formats it.
  public var publicationDate: String?
  /// The first date of the survey period, as FoodData Central formats it.
  public var startDate: String?
  /// The What We Eat in America category the food is filed under.
  public var wweiaFoodCategory: WWEIAFoodCategory?

  /// Creates a Survey food.
  /// - Parameters:
  ///   - dataType: The data type.
  ///   - description: The food's description.
  ///   - endDate: The last date of the survey period.
  ///   - fdcID: The food's FoodData Central identifier.
  ///   - foodAttributes: The food's attributes.
  ///   - foodClass: The record class.
  ///   - foodCode: The FNDDS food code.
  ///   - foodNutrients: The food's nutrient values.
  ///   - foodPortions: The household portions.
  ///   - inputFoods: The ingredients the food's values were computed from.
  ///   - publicationDate: The publication date.
  ///   - startDate: The first date of the survey period.
  ///   - wweiaFoodCategory: The What We Eat in America category.
  public init(
    dataType: FoodDataType = .survey,
    description: String,
    endDate: String? = nil,
    fdcID: FoodID,
    foodAttributes: [FoodAttribute]? = nil,
    foodClass: String? = nil,
    foodCode: String? = nil,
    foodNutrients: [FoodNutrient]? = nil,
    foodPortions: [FoodPortion]? = nil,
    inputFoods: [InputFood]? = nil,
    publicationDate: String? = nil,
    startDate: String? = nil,
    wweiaFoodCategory: WWEIAFoodCategory? = nil
  ) {
    self.dataType = dataType
    self.description = description
    self.endDate = endDate
    self.fdcID = fdcID
    self.foodAttributes = foodAttributes
    self.foodClass = foodClass
    self.foodCode = foodCode
    self.foodNutrients = foodNutrients
    self.foodPortions = foodPortions
    self.inputFoods = inputFoods
    self.publicationDate = publicationDate
    self.startDate = startDate
    self.wweiaFoodCategory = wweiaFoodCategory
  }

  enum CodingKeys: String, CodingKey {
    case dataType
    case description
    case endDate
    case fdcID = "fdcId"
    case foodAttributes
    case foodClass
    case foodCode
    case foodNutrients
    case foodPortions
    case inputFoods
    case publicationDate
    case startDate
    case wweiaFoodCategory
  }
}
