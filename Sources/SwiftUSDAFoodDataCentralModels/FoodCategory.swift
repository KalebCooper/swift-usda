/// The category or food group a food is filed under, such as Dairy and Egg Products.
///
/// ```swift
/// print(food.foodCategory?.description)  // Optional("Dairy and Egg Products")
/// ```
public struct FoodCategory: Codable, Hashable, Sendable {
  /// The category code, such as `0100`.
  public var code: String?
  /// The category name.
  public var description: String?
  /// The category's identifier.
  public var id: Int?

  /// Creates a category.
  /// - Parameters:
  ///   - code: The category code.
  ///   - description: The category name.
  ///   - id: The category's identifier.
  public init(code: String? = nil, description: String? = nil, id: Int? = nil) {
    self.code = code
    self.description = description
    self.id = id
  }
}
