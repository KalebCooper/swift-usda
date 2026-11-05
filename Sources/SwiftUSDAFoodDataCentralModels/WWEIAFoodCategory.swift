/// The What We Eat in America (WWEIA) category a Survey (FNDDS) food is filed under.
///
/// ```swift
/// print(food.wweiaFoodCategory?.wweiaFoodCategoryDescription ?? "")  // "Meat mixed dishes"
/// ```
public struct WWEIAFoodCategory: Codable, Hashable, Sendable {
  /// The category code, such as `3002`.
  public var wweiaFoodCategoryCode: Int?
  /// The category name.
  public var wweiaFoodCategoryDescription: String?

  /// Creates a category.
  /// - Parameters:
  ///   - wweiaFoodCategoryCode: The category code.
  ///   - wweiaFoodCategoryDescription: The category name.
  public init(wweiaFoodCategoryCode: Int? = nil, wweiaFoodCategoryDescription: String? = nil) {
    self.wweiaFoodCategoryCode = wweiaFoodCategoryCode
    self.wweiaFoodCategoryDescription = wweiaFoodCategoryDescription
  }
}
