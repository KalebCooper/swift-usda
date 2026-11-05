/// A food in a page of FoodData Central search results.
///
/// The fields are those the FoodData Central specification (version 1.0.1) lists for search
/// results; only ``fdcID`` and ``description`` are required there and here. The shape has not
/// been verified against a recorded response, and keys the specification does not list are not
/// kept. The publication date has two spellings, neither verified: the specification's
/// `publicationDate` and `publishedDate`, which the service is understood to send. Decoding reads
/// `publishedDate` first and `publicationDate` second; encoding always writes `publishedDate`, so
/// a decoded food survives a round trip unchanged. Nutrients accept two spellings the same way;
/// see ``SearchResultFoodNutrient``. Fields that apply to one data type, such as ``brandOwner`` for Branded foods, are `nil`
/// for the others. Dates and codes are kept as the provider's strings.
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
  /// The brand owner, for Branded foods.
  public var brandOwner: String?
  /// The data type the food belongs to.
  public var dataType: FoodDataType?
  /// The food's description, exactly as published.
  public var description: String
  /// The food's FoodData Central identifier.
  public var fdcID: FoodID
  /// The FNDDS food code, for Survey foods.
  public var foodCode: String?
  /// The food's nutrients, in the provider's order.
  public var foodNutrients: [SearchResultFoodNutrient]?
  /// The GTIN or UPC barcode, for Branded foods, kept as a string with its leading zeros.
  public var gtinUpc: String?
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

  /// Creates a search result food.
  /// - Parameters:
  ///   - additionalDescriptions: Any additional descriptions of the food.
  ///   - allHighlightFields: The search's highlighted fields.
  ///   - brandOwner: The brand owner, for Branded foods.
  ///   - dataType: The data type the food belongs to.
  ///   - description: The food's description.
  ///   - fdcID: The food's FoodData Central identifier.
  ///   - foodCode: The FNDDS food code, for Survey foods.
  ///   - foodNutrients: The food's nutrients.
  ///   - gtinUpc: The GTIN or UPC barcode, for Branded foods.
  ///   - ingredients: The label ingredients, for Branded foods.
  ///   - ndbNumber: The legacy NDB number, for Foundation and SR Legacy foods.
  ///   - publicationDate: The publication date.
  ///   - scientificName: The scientific name of the food.
  ///   - score: How well the food matches the search.
  public init(
    additionalDescriptions: String? = nil,
    allHighlightFields: String? = nil,
    brandOwner: String? = nil,
    dataType: FoodDataType? = nil,
    description: String,
    fdcID: FoodID,
    foodCode: String? = nil,
    foodNutrients: [SearchResultFoodNutrient]? = nil,
    gtinUpc: String? = nil,
    ingredients: String? = nil,
    ndbNumber: String? = nil,
    publicationDate: String? = nil,
    scientificName: String? = nil,
    score: Double? = nil
  ) {
    self.additionalDescriptions = additionalDescriptions
    self.allHighlightFields = allHighlightFields
    self.brandOwner = brandOwner
    self.dataType = dataType
    self.description = description
    self.fdcID = fdcID
    self.foodCode = foodCode
    self.foodNutrients = foodNutrients
    self.gtinUpc = gtinUpc
    self.ingredients = ingredients
    self.ndbNumber = ndbNumber
    self.publicationDate = publicationDate
    self.scientificName = scientificName
    self.score = score
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
    brandOwner = try container.decodeIfPresent(String.self, forKey: .brandOwner)
    dataType = try container.decodeIfPresent(FoodDataType.self, forKey: .dataType)
    description = try container.decode(String.self, forKey: .description)
    fdcID = try container.decode(FoodID.self, forKey: .fdcID)
    foodCode = try container.decodeIfPresent(String.self, forKey: .foodCode)
    foodNutrients = try container.decodeIfPresent(
      [SearchResultFoodNutrient].self, forKey: .foodNutrients)
    gtinUpc = try container.decodeIfPresent(String.self, forKey: .gtinUpc)
    ingredients = try container.decodeIfPresent(String.self, forKey: .ingredients)
    ndbNumber = try container.decodeIntegerOrStringIfPresent(forKey: .ndbNumber)
    publicationDate =
      try container.decodeIfPresent(String.self, forKey: .publishedDate)
      ?? container.decodeIfPresent(String.self, forKey: .publicationDate)
    scientificName = try container.decodeIfPresent(String.self, forKey: .scientificName)
    score = try container.decodeIfPresent(Double.self, forKey: .score)
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
    try container.encodeIfPresent(brandOwner, forKey: .brandOwner)
    try container.encodeIfPresent(dataType, forKey: .dataType)
    try container.encode(description, forKey: .description)
    try container.encode(fdcID, forKey: .fdcID)
    try container.encodeIfPresent(foodCode, forKey: .foodCode)
    try container.encodeIfPresent(foodNutrients, forKey: .foodNutrients)
    try container.encodeIfPresent(gtinUpc, forKey: .gtinUpc)
    try container.encodeIfPresent(ingredients, forKey: .ingredients)
    try container.encodeIfPresent(ndbNumber, forKey: .ndbNumber)
    try container.encodeIfPresent(publicationDate, forKey: .publishedDate)
    try container.encodeIfPresent(scientificName, forKey: .scientificName)
    try container.encodeIfPresent(score, forKey: .score)
  }

  enum CodingKeys: String, CodingKey {
    case additionalDescriptions
    case allHighlightFields
    case brandOwner
    case dataType
    case description
    case fdcID = "fdcId"
    case foodCode
    case foodNutrients
    case gtinUpc
    case ingredients
    case ndbNumber
    case publicationDate
    case publishedDate
    case scientificName
    case score
  }
}
