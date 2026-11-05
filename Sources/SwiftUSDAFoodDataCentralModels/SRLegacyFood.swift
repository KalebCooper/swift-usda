/// A Standard Reference legacy food in FoodData Central's full format.
///
/// SR Legacy is the final 2018 release of the USDA National Nutrient Database for Standard
/// Reference, kept unchanged. Every field but the identity is optional because FoodData Central
/// documents only ``fdcID``, ``dataType``, and ``description`` as always present. FoodData Central
/// sends ``ndbNumber`` as a JSON integer in full records and as a JSON string in abridged ones;
/// both decode into the one string, and encoding writes a string.
///
/// ```swift
/// if case .srLegacy(let food) = try JSONDecoder().decode(Food.self, from: body) {
///   print(food.ndbNumber ?? "", food.description)
/// }
/// ```
public struct SRLegacyFood: Codable, Hashable, Sendable {
  /// The data type, ``FoodDataType/srLegacy``.
  public var dataType: FoodDataType
  /// The food's description, exactly as published.
  public var description: String
  /// The food's FoodData Central identifier.
  public var fdcID: FoodID
  /// The food's attributes, such as common names and taxon links.
  public var foodAttributes: [FoodAttribute]?
  /// The category the food is filed under.
  public var foodCategory: FoodCategory?
  /// The record class exactly as sent.
  public var foodClass: String?
  /// The food's nutrient values, in the provider's order.
  public var foodNutrients: [FoodNutrient]?
  /// The household portions and their gram weights.
  public var foodPortions: [FoodPortion]?
  /// Whether the record is kept for historical reference.
  public var isHistoricalReference: Bool?
  /// The legacy NDB number as a string, such as `9427`.
  public var ndbNumber: String?
  /// The factors for converting the food's nutrient values.
  public var nutrientConversionFactors: [NutrientConversionFactor]?
  /// The publication date as FoodData Central formats it.
  public var publicationDate: String?
  /// The scientific name of the food's source, when it has one.
  public var scientificName: String?

  /// Creates an SR Legacy food.
  /// - Parameters:
  ///   - dataType: The data type.
  ///   - description: The food's description.
  ///   - fdcID: The food's FoodData Central identifier.
  ///   - foodAttributes: The food's attributes.
  ///   - foodCategory: The category the food is filed under.
  ///   - foodClass: The record class.
  ///   - foodNutrients: The food's nutrient values.
  ///   - foodPortions: The household portions.
  ///   - isHistoricalReference: Whether the record is kept for historical reference.
  ///   - ndbNumber: The legacy NDB number.
  ///   - nutrientConversionFactors: The factors for converting the food's nutrient values.
  ///   - publicationDate: The publication date.
  ///   - scientificName: The scientific name of the food's source.
  public init(
    dataType: FoodDataType = .srLegacy,
    description: String,
    fdcID: FoodID,
    foodAttributes: [FoodAttribute]? = nil,
    foodCategory: FoodCategory? = nil,
    foodClass: String? = nil,
    foodNutrients: [FoodNutrient]? = nil,
    foodPortions: [FoodPortion]? = nil,
    isHistoricalReference: Bool? = nil,
    ndbNumber: String? = nil,
    nutrientConversionFactors: [NutrientConversionFactor]? = nil,
    publicationDate: String? = nil,
    scientificName: String? = nil
  ) {
    self.dataType = dataType
    self.description = description
    self.fdcID = fdcID
    self.foodAttributes = foodAttributes
    self.foodCategory = foodCategory
    self.foodClass = foodClass
    self.foodNutrients = foodNutrients
    self.foodPortions = foodPortions
    self.isHistoricalReference = isHistoricalReference
    self.ndbNumber = ndbNumber
    self.nutrientConversionFactors = nutrientConversionFactors
    self.publicationDate = publicationDate
    self.scientificName = scientificName
  }

  /// Decodes an SR Legacy food, accepting a string or an integer ``ndbNumber``.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when `dataType`, `description`, or `fdcId` is missing, or when a
  ///   field has another shape.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    dataType = try container.decode(FoodDataType.self, forKey: .dataType)
    description = try container.decode(String.self, forKey: .description)
    fdcID = try container.decode(FoodID.self, forKey: .fdcID)
    foodAttributes = try container.decodeIfPresent([FoodAttribute].self, forKey: .foodAttributes)
    foodCategory = try container.decodeIfPresent(FoodCategory.self, forKey: .foodCategory)
    foodClass = try container.decodeIfPresent(String.self, forKey: .foodClass)
    foodNutrients = try container.decodeIfPresent([FoodNutrient].self, forKey: .foodNutrients)
    foodPortions = try container.decodeIfPresent([FoodPortion].self, forKey: .foodPortions)
    isHistoricalReference = try container.decodeIfPresent(
      Bool.self, forKey: .isHistoricalReference)
    ndbNumber = try container.decodeIntegerOrStringIfPresent(forKey: .ndbNumber)
    nutrientConversionFactors = try container.decodeIfPresent(
      [NutrientConversionFactor].self, forKey: .nutrientConversionFactors)
    publicationDate = try container.decodeIfPresent(String.self, forKey: .publicationDate)
    scientificName = try container.decodeIfPresent(String.self, forKey: .scientificName)
  }

  enum CodingKeys: String, CodingKey {
    case dataType
    case description
    case fdcID = "fdcId"
    case foodAttributes
    case foodCategory
    case foodClass
    case foodNutrients
    case foodPortions
    case isHistoricalReference
    case ndbNumber
    case nutrientConversionFactors
    case publicationDate
    case scientificName
  }
}
