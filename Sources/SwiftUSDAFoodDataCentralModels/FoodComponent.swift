/// A physical component of a Foundation food sample, such as a peel or a bone.
///
/// ```swift
/// let refuse = food.foodComponents?.filter { $0.isRefuse == true }
/// ```
public struct FoodComponent: Codable, Hashable, Sendable {
  /// The number of observations the values rest on.
  public var dataPoints: Int?
  /// The component's weight in grams.
  public var gramWeight: Double?
  /// The component's identifier.
  public var id: Int?
  /// Whether the component is refuse, the inedible part.
  public var isRefuse: Bool?
  /// The earliest year a sample was acquired.
  public var minYearAcquired: Int?
  /// The component's name.
  public var name: String?
  /// The component's share of the food's weight, in percent.
  public var percentWeight: Double?

  /// Creates a component.
  /// - Parameters:
  ///   - dataPoints: The number of observations the values rest on.
  ///   - gramWeight: The component's weight in grams.
  ///   - id: The component's identifier.
  ///   - isRefuse: Whether the component is refuse.
  ///   - minYearAcquired: The earliest year a sample was acquired.
  ///   - name: The component's name.
  ///   - percentWeight: The component's share of the food's weight, in percent.
  public init(
    dataPoints: Int? = nil,
    gramWeight: Double? = nil,
    id: Int? = nil,
    isRefuse: Bool? = nil,
    minYearAcquired: Int? = nil,
    name: String? = nil,
    percentWeight: Double? = nil
  ) {
    self.dataPoints = dataPoints
    self.gramWeight = gramWeight
    self.id = id
    self.isRefuse = isRefuse
    self.minYearAcquired = minYearAcquired
    self.name = name
    self.percentWeight = percentWeight
  }
}
