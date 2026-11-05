/// The kind of a ``FoodAttribute``, such as Common Name or Adjustments.
///
/// ```swift
/// print(attribute.foodAttributeType?.description ?? "")
/// ```
public struct FoodAttributeType: Codable, Hashable, Sendable {
  /// What the kind of attribute covers.
  public var description: String?
  /// The attribute type's identifier.
  public var id: Int?
  /// The attribute type's name.
  public var name: String?

  /// Creates an attribute type.
  /// - Parameters:
  ///   - description: What the kind of attribute covers.
  ///   - id: The attribute type's identifier.
  ///   - name: The attribute type's name.
  public init(description: String? = nil, id: Int? = nil, name: String? = nil) {
    self.description = description
    self.id = id
    self.name = name
  }
}
