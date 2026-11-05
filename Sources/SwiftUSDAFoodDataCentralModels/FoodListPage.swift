/// One page of a food list: the abridged foods FoodData Central returned for one page number.
///
/// FoodData Central sends a list page as a bare array with no page number, size, or total, so this
/// value pairs the foods with the page number and size that were requested. It is assembled by the
/// executor, not decoded from the wire; its `Codable` form is this value's own fields, for storing a
/// page. Pass it to ``FoodListQuery/next(after:)`` to describe the following page.
///
/// ```swift
/// let page = FoodListPage(foods: foods, pageNumber: query.pageNumber, pageSize: query.pageSize)
/// if let following = try query.next(after: page) {
///   print(following.pageNumber)
/// }
/// ```
public struct FoodListPage: Codable, Hashable, Sendable {
  /// The page's foods, in the order the service returned them.
  public var foods: [AbridgedFood]
  /// The one-based page number that was requested.
  public var pageNumber: Int
  /// The page size that was requested, the most foods the page can hold.
  public var pageSize: Int

  /// Creates a page.
  /// - Parameters:
  ///   - foods: The foods the service returned.
  ///   - pageNumber: The one-based page number that was requested.
  ///   - pageSize: The page size that was requested.
  public init(foods: [AbridgedFood], pageNumber: Int, pageSize: Int) {
    self.foods = foods
    self.pageNumber = pageNumber
    self.pageSize = pageSize
  }
}
