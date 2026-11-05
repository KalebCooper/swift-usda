/// A factor for converting a food's nutrient values, such as nitrogen to protein or proximates to
/// calories.
///
/// A ``type`` of `.ProteinConversionFactor` carries one ``value``. A ``type`` of
/// `.CalorieConversionFactor` carries ``proteinValue``, ``fatValue``, and ``carbohydrateValue``
/// instead. Other types are kept as sent.
///
/// ```swift
/// for factor in food.nutrientConversionFactors ?? [] {
///   print(factor.name ?? "", factor.value ?? factor.proteinValue ?? 0)
/// }
/// ```
public struct NutrientConversionFactor: Codable, Hashable, Sendable {
  /// The calories per gram of carbohydrate, for a calorie conversion factor.
  public var carbohydrateValue: Double?
  /// The calories per gram of fat, for a calorie conversion factor.
  public var fatValue: Double?
  /// The factor's identifier.
  public var id: Int?
  /// The factor's name, such as `Protein From Nitrogen`.
  public var name: String?
  /// The calories per gram of protein, for a calorie conversion factor.
  public var proteinValue: Double?
  /// The factor type exactly as sent, such as `.ProteinConversionFactor`.
  public var type: String?
  /// The factor's value, for a protein conversion factor.
  public var value: Double?

  /// Creates a conversion factor.
  /// - Parameters:
  ///   - carbohydrateValue: The calories per gram of carbohydrate.
  ///   - fatValue: The calories per gram of fat.
  ///   - id: The factor's identifier.
  ///   - name: The factor's name.
  ///   - proteinValue: The calories per gram of protein.
  ///   - type: The factor type.
  ///   - value: The factor's value.
  public init(
    carbohydrateValue: Double? = nil,
    fatValue: Double? = nil,
    id: Int? = nil,
    name: String? = nil,
    proteinValue: Double? = nil,
    type: String? = nil,
    value: Double? = nil
  ) {
    self.carbohydrateValue = carbohydrateValue
    self.fatValue = fatValue
    self.id = id
    self.name = name
    self.proteinValue = proteinValue
    self.type = type
    self.value = value
  }
}
