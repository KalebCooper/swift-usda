/// The unit a food portion is measured in, such as a cup or a tablespoon.
///
/// ```swift
/// print(portion.measureUnit?.abbreviation)  // Optional("cup")
/// ```
public struct MeasureUnit: Codable, Hashable, Sendable {
  /// The unit's abbreviation.
  public var abbreviation: String?
  /// The unit's identifier.
  public var id: Int?
  /// The unit's name.
  public var name: String?

  /// Creates a measure unit.
  /// - Parameters:
  ///   - abbreviation: The unit's abbreviation.
  ///   - id: The unit's identifier.
  ///   - name: The unit's name.
  public init(abbreviation: String? = nil, id: Int? = nil, name: String? = nil) {
    self.abbreviation = abbreviation
    self.id = id
    self.name = name
  }
}
