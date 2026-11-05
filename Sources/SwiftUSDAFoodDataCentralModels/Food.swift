/// A food in FoodData Central's full format, in the shape its data type defines.
///
/// FoodData Central returns a different record shape for each data type. Decoding reads the
/// record's `dataType` and decodes the matching shape. A data type without a modeled shape, such
/// as Experimental or one FoodData Central adds later, decodes as ``other(dataType:_:)`` with the
/// whole record kept as JSON, so nothing is lost and nothing fails. Encoding writes the record back
/// in its original shape.
///
/// ```swift
/// switch try JSONDecoder().decode(Food.self, from: body) {
/// case .branded(let food): print(food.description)
/// case .foundation(let food): print(food.description)
/// case .other(let dataType, _): print("Not modeled:", dataType.rawValue)
/// case .srLegacy(let food): print(food.description)
/// case .survey(let food): print(food.description)
/// }
/// ```
public enum Food: Codable, Hashable, Sendable {
  /// A Branded food.
  case branded(BrandedFood)
  /// A Foundation food.
  case foundation(FoundationFood)
  /// A record whose data type has no modeled shape, kept whole.
  case other(dataType: FoodDataType, JSONValue)
  /// A Standard Reference legacy food.
  case srLegacy(SRLegacyFood)
  /// A Survey (FNDDS) food.
  case survey(SurveyFood)

  private enum CodingKeys: String, CodingKey {
    case dataType
  }

  /// Decodes the record in the shape its `dataType` names.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when the record has no string `dataType`, or when a record of a
  ///   modeled data type does not match its shape.
  public init(from decoder: any Decoder) throws {
    let dataType = try decoder.container(keyedBy: CodingKeys.self)
      .decode(FoodDataType.self, forKey: .dataType)
    switch dataType {
    case .branded: self = .branded(try BrandedFood(from: decoder))
    case .foundation: self = .foundation(try FoundationFood(from: decoder))
    case .srLegacy: self = .srLegacy(try SRLegacyFood(from: decoder))
    case .survey: self = .survey(try SurveyFood(from: decoder))
    default: self = .other(dataType: dataType, try JSONValue(from: decoder))
    }
  }

  /// Encodes the record in its original shape.
  /// - Parameter encoder: The encoder to write.
  /// - Throws: Any error from the encoder.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .branded(let food): try food.encode(to: encoder)
    case .foundation(let food): try food.encode(to: encoder)
    case .other(_, let record): try record.encode(to: encoder)
    case .srLegacy(let food): try food.encode(to: encoder)
    case .survey(let food): try food.encode(to: encoder)
    }
  }
}
