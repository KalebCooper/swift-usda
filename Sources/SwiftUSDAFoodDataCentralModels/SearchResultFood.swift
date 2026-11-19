/// A food in a page of FoodData Central search results.
///
/// The fields are those recorded search responses carry that this package models; only
/// ``fdcID`` and ``description`` are required. Keys the type does not declare, such as the
/// per-food measure and attribute arrays, are not kept. The service sends the publication date as
/// `publishedDate`; the FoodData Central specification (version 1.0.1) names it
/// `publicationDate`. Decoding reads `publishedDate` first and `publicationDate` second; encoding
/// always writes `publishedDate`, so a decoded food survives a round trip unchanged. Nutrients
/// accept two spellings the same way; see ``SearchResultFoodNutrient``. Fields that apply to one
/// data type, such as ``brandOwner`` for Branded foods, are `nil` for the others. Dates, units,
/// and codes are kept as the provider's strings.
///
/// ```swift
/// for food in page.foods {
///   print(food.fdcID, food.description, food.score ?? 0)
/// }
/// ```
public struct SearchResultFood: Codable, Hashable, Sendable {
  /// Any additional descriptions of the food.
  public var additionalDescriptions: String?
  /// The search's highlighted fields, as the service sends them.
  public var allHighlightFields: String?
  /// The brand name, for Branded foods.
  public var brandName: String?
  /// The brand owner, for Branded foods.
  public var brandOwner: String?
  /// The data type the food belongs to.
  public var dataType: FoodDataType?
  /// The food's description, exactly as published.
  public var description: String
  /// The food's FoodData Central identifier.
  public var fdcID: FoodID
  /// The food's category as text, such as `Cheese` or `Dairy and Egg Products`.
  public var foodCategory: String?
  /// The FNDDS food code, for Survey foods.
  public var foodCode: String?
  /// The food's nutrients, in the provider's order.
  public var foodNutrients: [SearchResultFoodNutrient]?
  /// The GTIN or UPC barcode, for Branded foods, kept as a string with its leading zeros.
  public var gtinUpc: String?
  /// The household serving as printed on the label, such as `1 ONZ`, for Branded foods.
  public var householdServingFullText: String?
  /// The ingredients as they appear on the label, for Branded foods.
  public var ingredients: String?
  /// The legacy NDB number, for Foundation and SR Legacy foods, kept as a string whether it
  /// arrives as a JSON integer or string.
  public var ndbNumber: String?
  /// The publication date as FoodData Central formats it, such as `4/1/2019`, from
  /// `publishedDate` or `publicationDate`.
  public var publicationDate: String?
  /// The scientific name of the food.
  public var scientificName: String?
  /// How well the food matches the search, relative to the other results.
  public var score: Double?
  /// The serving size in ``servingSizeUnit``, for Branded foods.
  public var servingSize: Double?
  /// The unit of ``servingSize`` exactly as sent, such as `g` or `GRM`, for Branded foods.
  public var servingSizeUnit: String?
  /// The channels a Branded food is sold through, as sent, including values such as
  /// `NO_TRADE_CHANNEL` that ``TradeChannel`` names no constant for.
  public var tradeChannels: [TradeChannel]?

  /// Creates a search result food.
  /// - Parameters:
  ///   - additionalDescriptions: Any additional descriptions of the food.
  ///   - allHighlightFields: The search's highlighted fields.
  ///   - brandName: The brand name, for Branded foods.
  ///   - brandOwner: The brand owner, for Branded foods.
  ///   - dataType: The data type the food belongs to.
  ///   - description: The food's description.
  ///   - fdcID: The food's FoodData Central identifier.
  ///   - foodCategory: The food's category as text.
  ///   - foodCode: The FNDDS food code, for Survey foods.
  ///   - foodNutrients: The food's nutrients.
  ///   - gtinUpc: The GTIN or UPC barcode, for Branded foods.
  ///   - householdServingFullText: The household serving, for Branded foods.
  ///   - ingredients: The label ingredients, for Branded foods.
  ///   - ndbNumber: The legacy NDB number, for Foundation and SR Legacy foods.
  ///   - publicationDate: The publication date.
  ///   - scientificName: The scientific name of the food.
  ///   - score: How well the food matches the search.
  ///   - servingSize: The serving size, for Branded foods.
  ///   - servingSizeUnit: The unit of `servingSize`, for Branded foods.
  ///   - tradeChannels: The channels a Branded food is sold through.
  public init(
    additionalDescriptions: String? = nil,
    allHighlightFields: String? = nil,
    brandName: String? = nil,
    brandOwner: String? = nil,
    dataType: FoodDataType? = nil,
    description: String,
    fdcID: FoodID,
    foodCategory: String? = nil,
    foodCode: String? = nil,
    foodNutrients: [SearchResultFoodNutrient]? = nil,
    gtinUpc: String? = nil,
    householdServingFullText: String? = nil,
    ingredients: String? = nil,
    ndbNumber: String? = nil,
    publicationDate: String? = nil,
    scientificName: String? = nil,
    score: Double? = nil,
    servingSize: Double? = nil,
    servingSizeUnit: String? = nil,
    tradeChannels: [TradeChannel]? = nil
  ) {
    self.additionalDescriptions = additionalDescriptions
    self.allHighlightFields = allHighlightFields
    self.brandName = brandName
    self.brandOwner = brandOwner
    self.dataType = dataType
    self.description = description
    self.fdcID = fdcID
    self.foodCategory = foodCategory
    self.foodCode = foodCode
    self.foodNutrients = foodNutrients
    self.gtinUpc = gtinUpc
    self.householdServingFullText = householdServingFullText
    self.ingredients = ingredients
    self.ndbNumber = ndbNumber
    self.publicationDate = publicationDate
    self.scientificName = scientificName
    self.score = score
    self.servingSize = servingSize
    self.servingSizeUnit = servingSizeUnit
    self.tradeChannels = tradeChannels
  }

  /// Decodes a search result food, accepting a string or an integer ``ndbNumber`` and either
  /// spelling of the publication date, `publishedDate` first.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when `description` or `fdcId` is missing, or when a field has
  ///   another shape.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    additionalDescriptions = try container.decodeIfPresent(
      String.self, forKey: .additionalDescriptions)
    allHighlightFields = try container.decodeIfPresent(String.self, forKey: .allHighlightFields)
    brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
    brandOwner = try container.decodeIfPresent(String.self, forKey: .brandOwner)
    dataType = try container.decodeIfPresent(FoodDataType.self, forKey: .dataType)
    description = try container.decode(String.self, forKey: .description)
    fdcID = try container.decode(FoodID.self, forKey: .fdcID)
    foodCategory = try container.decodeIfPresent(String.self, forKey: .foodCategory)
    foodCode = try container.decodeIfPresent(String.self, forKey: .foodCode)
    foodNutrients = try container.decodeIfPresent(
      [SearchResultFoodNutrient].self, forKey: .foodNutrients)
    gtinUpc = try container.decodeIfPresent(String.self, forKey: .gtinUpc)
    householdServingFullText = try container.decodeIfPresent(
      String.self, forKey: .householdServingFullText)
    ingredients = try container.decodeIfPresent(String.self, forKey: .ingredients)
    ndbNumber = try container.decodeIntegerOrStringIfPresent(forKey: .ndbNumber)
    publicationDate =
      try container.decodeIfPresent(String.self, forKey: .publishedDate)
      ?? container.decodeIfPresent(String.self, forKey: .publicationDate)
    scientificName = try container.decodeIfPresent(String.self, forKey: .scientificName)
    score = try container.decodeIfPresent(Double.self, forKey: .score)
    servingSize = try container.decodeIfPresent(Double.self, forKey: .servingSize)
    servingSizeUnit = try container.decodeIfPresent(String.self, forKey: .servingSizeUnit)
    tradeChannels = try container.decodeIfPresent([TradeChannel].self, forKey: .tradeChannels)
  }

  /// Encodes the food, writing the publication date as `publishedDate`.
  ///
  /// `nil` fields are omitted, and ``ndbNumber`` is written as a string.
  /// - Parameter encoder: The encoder to write to.
  /// - Throws: An error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(additionalDescriptions, forKey: .additionalDescriptions)
    try container.encodeIfPresent(allHighlightFields, forKey: .allHighlightFields)
    try container.encodeIfPresent(brandName, forKey: .brandName)
    try container.encodeIfPresent(brandOwner, forKey: .brandOwner)
    try container.encodeIfPresent(dataType, forKey: .dataType)
    try container.encode(description, forKey: .description)
    try container.encode(fdcID, forKey: .fdcID)
    try container.encodeIfPresent(foodCategory, forKey: .foodCategory)
    try container.encodeIfPresent(foodCode, forKey: .foodCode)
    try container.encodeIfPresent(foodNutrients, forKey: .foodNutrients)
    try container.encodeIfPresent(gtinUpc, forKey: .gtinUpc)
    try container.encodeIfPresent(householdServingFullText, forKey: .householdServingFullText)
    try container.encodeIfPresent(ingredients, forKey: .ingredients)
    try container.encodeIfPresent(ndbNumber, forKey: .ndbNumber)
    try container.encodeIfPresent(publicationDate, forKey: .publishedDate)
    try container.encodeIfPresent(scientificName, forKey: .scientificName)
    try container.encodeIfPresent(score, forKey: .score)
    try container.encodeIfPresent(servingSize, forKey: .servingSize)
    try container.encodeIfPresent(servingSizeUnit, forKey: .servingSizeUnit)
    try container.encodeIfPresent(tradeChannels, forKey: .tradeChannels)
  }

  enum CodingKeys: String, CodingKey {
    case additionalDescriptions
    case allHighlightFields
    case brandName
    case brandOwner
    case dataType
    case description
    case fdcID = "fdcId"
    case foodCategory
    case foodCode
    case foodNutrients
    case gtinUpc
    case householdServingFullText
    case ingredients
    case ndbNumber
    case publicationDate
    case publishedDate
    case scientificName
    case score
    case servingSize
    case servingSizeUnit
    case tradeChannels
  }
}
