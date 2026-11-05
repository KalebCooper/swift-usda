/// A Branded food in FoodData Central's full format: a commercial product's label data, as its
/// brand owner or a data provider submitted it.
///
/// Every field but the identity is optional because FoodData Central documents only ``fdcID``,
/// ``dataType``, and ``description`` as always present. Dates, codes, and units are kept as the
/// provider's strings, and the serving size is kept in the unit ``servingSizeUnit`` names.
///
/// ```swift
/// if case .branded(let food) = try JSONDecoder().decode(Food.self, from: body) {
///   print(food.brandOwner ?? "", food.labelNutrients?.calories?.value ?? 0)
/// }
/// ```
public struct BrandedFood: Codable, Hashable, Sendable {
  /// The date the product became available, as FoodData Central formats it.
  public var availableDate: String?
  /// The product's category, such as `Popcorn, Peanuts, Seeds & Related Snacks`.
  public var brandedFoodCategory: String?
  /// The product's brand name.
  public var brandName: String?
  /// The company that owns the brand.
  public var brandOwner: String?
  /// The source of the data, such as `LI` for label insight, exactly as sent.
  public var dataSource: String?
  /// The data type, ``FoodDataType/branded``.
  public var dataType: FoodDataType
  /// The food's description, exactly as published.
  public var description: String
  /// The date the product was discontinued, as FoodData Central formats it.
  public var discontinuedDate: String?
  /// The food's FoodData Central identifier.
  public var fdcID: FoodID
  /// The food's attributes.
  public var foodAttributes: [FoodAttribute]?
  /// The record class exactly as sent.
  public var foodClass: String?
  /// The food's nutrient values, in the provider's order.
  public var foodNutrients: [FoodNutrient]?
  /// The product's Global Product Classification class code.
  public var gpcClassCode: Int?
  /// The product's GTIN or UPC, kept as a string so leading zeros survive.
  public var gtinUpc: String?
  /// The household serving as printed on the label, such as `1 ONZ`.
  public var householdServingFullText: String?
  /// The ingredient statement exactly as printed.
  public var ingredients: String?
  /// The nutrient values printed on the label, per serving.
  public var labelNutrients: LabelNutrients?
  /// The country the product is sold in, such as `United States`.
  public var marketCountry: String?
  /// The date the record was last modified, as FoodData Central formats it.
  public var modifiedDate: String?
  /// The package weight as printed, exactly as sent.
  public var packageWeight: String?
  /// The product's preparation state, such as `UNPREPARED`, exactly as sent.
  public var preparationStateCode: String?
  /// The publication date as FoodData Central formats it.
  public var publicationDate: String?
  /// The serving size, in ``servingSizeUnit``.
  public var servingSize: Double?
  /// The unit of ``servingSize``, such as `g`, exactly as sent.
  public var servingSizeUnit: String?
  /// The product's short description, exactly as sent.
  public var shortDescription: String?
  /// The channels the product is sold through, such as `GROCERY`, exactly as sent.
  public var tradeChannel: [String]?

  /// Creates a Branded food.
  /// - Parameters:
  ///   - availableDate: The date the product became available.
  ///   - brandedFoodCategory: The product's category.
  ///   - brandName: The product's brand name.
  ///   - brandOwner: The company that owns the brand.
  ///   - dataSource: The source of the data.
  ///   - dataType: The data type.
  ///   - description: The food's description.
  ///   - discontinuedDate: The date the product was discontinued.
  ///   - fdcID: The food's FoodData Central identifier.
  ///   - foodAttributes: The food's attributes.
  ///   - foodClass: The record class.
  ///   - foodNutrients: The food's nutrient values.
  ///   - gpcClassCode: The product's Global Product Classification class code.
  ///   - gtinUpc: The product's GTIN or UPC.
  ///   - householdServingFullText: The household serving as printed on the label.
  ///   - ingredients: The ingredient statement.
  ///   - labelNutrients: The nutrient values printed on the label.
  ///   - marketCountry: The country the product is sold in.
  ///   - modifiedDate: The date the record was last modified.
  ///   - packageWeight: The package weight as printed.
  ///   - preparationStateCode: The product's preparation state.
  ///   - publicationDate: The publication date.
  ///   - servingSize: The serving size.
  ///   - servingSizeUnit: The unit of `servingSize`.
  ///   - shortDescription: The product's short description.
  ///   - tradeChannel: The channels the product is sold through.
  public init(
    availableDate: String? = nil,
    brandedFoodCategory: String? = nil,
    brandName: String? = nil,
    brandOwner: String? = nil,
    dataSource: String? = nil,
    dataType: FoodDataType = .branded,
    description: String,
    discontinuedDate: String? = nil,
    fdcID: FoodID,
    foodAttributes: [FoodAttribute]? = nil,
    foodClass: String? = nil,
    foodNutrients: [FoodNutrient]? = nil,
    gpcClassCode: Int? = nil,
    gtinUpc: String? = nil,
    householdServingFullText: String? = nil,
    ingredients: String? = nil,
    labelNutrients: LabelNutrients? = nil,
    marketCountry: String? = nil,
    modifiedDate: String? = nil,
    packageWeight: String? = nil,
    preparationStateCode: String? = nil,
    publicationDate: String? = nil,
    servingSize: Double? = nil,
    servingSizeUnit: String? = nil,
    shortDescription: String? = nil,
    tradeChannel: [String]? = nil
  ) {
    self.availableDate = availableDate
    self.brandedFoodCategory = brandedFoodCategory
    self.brandName = brandName
    self.brandOwner = brandOwner
    self.dataSource = dataSource
    self.dataType = dataType
    self.description = description
    self.discontinuedDate = discontinuedDate
    self.fdcID = fdcID
    self.foodAttributes = foodAttributes
    self.foodClass = foodClass
    self.foodNutrients = foodNutrients
    self.gpcClassCode = gpcClassCode
    self.gtinUpc = gtinUpc
    self.householdServingFullText = householdServingFullText
    self.ingredients = ingredients
    self.labelNutrients = labelNutrients
    self.marketCountry = marketCountry
    self.modifiedDate = modifiedDate
    self.packageWeight = packageWeight
    self.preparationStateCode = preparationStateCode
    self.publicationDate = publicationDate
    self.servingSize = servingSize
    self.servingSizeUnit = servingSizeUnit
    self.shortDescription = shortDescription
    self.tradeChannel = tradeChannel
  }

  enum CodingKeys: String, CodingKey {
    case availableDate
    case brandedFoodCategory
    case brandName
    case brandOwner
    case dataSource
    case dataType
    case description
    case discontinuedDate
    case fdcID = "fdcId"
    case foodAttributes
    case foodClass
    case foodNutrients
    case gpcClassCode
    case gtinUpc
    case householdServingFullText
    case ingredients
    case labelNutrients
    case marketCountry
    case modifiedDate
    case packageWeight
    case preparationStateCode
    case publicationDate
    case servingSize
    case servingSizeUnit
    case shortDescription
    case tradeChannel
  }
}
