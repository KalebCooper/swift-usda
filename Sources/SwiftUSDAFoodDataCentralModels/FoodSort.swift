/// How FoodData Central orders foods: a field, and optionally a direction.
///
/// FoodData Central applies `sortOrder` only with `sortBy`, so a direction exists only inside a
/// sort. Without an order, no `sortOrder` is sent and the service's default direction applies; the
/// service does not document that default.
///
/// ```swift
/// let query = try FoodListQuery(sort: FoodSort(field: .fdcID, order: .descending))
/// ```
public struct FoodSort: Hashable, Sendable {
  /// The field to sort by, sent as `sortBy`.
  public let field: FoodSortField
  /// The direction, sent as `sortOrder`, or `nil` to send none.
  public let order: FoodSortOrder?

  /// Creates a sort.
  /// - Parameters:
  ///   - field: The field to sort by.
  ///   - order: The direction, or `nil` to leave it to the service.
  public init(field: FoodSortField, order: FoodSortOrder? = nil) {
    self.field = field
    self.order = order
  }
}
