/// An ingredient a Survey (FNDDS) food's values were computed from.
///
/// FoodData Central notes that not every input food carries every field, so all fields are
/// optional. The nested ``inputFood`` record is kept whole as JSON, so a sparse or differently
/// shaped record never fails the whole Survey food.
///
/// ```swift
/// for input in food.inputFoods ?? [] {
///   print(input.ingredientDescription ?? "", input.ingredientWeight ?? 0)
/// }
/// ```
public struct InputFood: Codable, Hashable, Sendable {
  /// The amount of the ingredient, in ``unit``.
  public var amount: Double?
  /// The ingredient's description as the food record states it.
  public var foodDescription: String?
  /// The input record's identifier.
  public var id: Int?
  /// The ingredient's code.
  public var ingredientCode: Int?
  /// The ingredient's description.
  public var ingredientDescription: String?
  /// The ingredient's weight in grams.
  public var ingredientWeight: Double?
  /// The ingredient's food record kept whole, when the provider includes it.
  public var inputFood: JSONValue?
  /// The portion code, exactly as sent.
  public var portionCode: String?
  /// The portion's description, such as `1 tablespoon`.
  public var portionDescription: String?
  /// The code of the nutrient retention factor applied to the ingredient.
  public var retentionCode: Int?
  /// The nutrient retention factor applied to the ingredient.
  public var retentionFactor: InputFoodRetentionFactor?
  /// The ingredient's position in the recipe.
  public var sequenceNumber: Int?
  /// The survey flag, exactly as sent.
  public var surveyFlag: Int?
  /// The unit of ``amount``, such as `TB`, exactly as sent.
  public var unit: String?

  /// Creates a Survey input food.
  /// - Parameters:
  ///   - amount: The amount of the ingredient.
  ///   - foodDescription: The ingredient's description as the food record states it.
  ///   - id: The input record's identifier.
  ///   - ingredientCode: The ingredient's code.
  ///   - ingredientDescription: The ingredient's description.
  ///   - ingredientWeight: The ingredient's weight in grams.
  ///   - inputFood: The ingredient's food record kept whole.
  ///   - portionCode: The portion code.
  ///   - portionDescription: The portion's description.
  ///   - retentionCode: The code of the retention factor applied.
  ///   - retentionFactor: The retention factor applied.
  ///   - sequenceNumber: The ingredient's position in the recipe.
  ///   - surveyFlag: The survey flag.
  ///   - unit: The unit of `amount`.
  public init(
    amount: Double? = nil,
    foodDescription: String? = nil,
    id: Int? = nil,
    ingredientCode: Int? = nil,
    ingredientDescription: String? = nil,
    ingredientWeight: Double? = nil,
    inputFood: JSONValue? = nil,
    portionCode: String? = nil,
    portionDescription: String? = nil,
    retentionCode: Int? = nil,
    retentionFactor: InputFoodRetentionFactor? = nil,
    sequenceNumber: Int? = nil,
    surveyFlag: Int? = nil,
    unit: String? = nil
  ) {
    self.amount = amount
    self.foodDescription = foodDescription
    self.id = id
    self.ingredientCode = ingredientCode
    self.ingredientDescription = ingredientDescription
    self.ingredientWeight = ingredientWeight
    self.inputFood = inputFood
    self.portionCode = portionCode
    self.portionDescription = portionDescription
    self.retentionCode = retentionCode
    self.retentionFactor = retentionFactor
    self.sequenceNumber = sequenceNumber
    self.surveyFlag = surveyFlag
    self.unit = unit
  }
}
