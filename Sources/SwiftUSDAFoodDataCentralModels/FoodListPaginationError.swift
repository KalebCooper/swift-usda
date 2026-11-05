/// Why a food list cannot safely continue to another page.
///
/// ``FoodListQuery/next(after:)`` throws the page-checking cases rather than guess a successor, so
/// a traversal never ends quietly on a page it cannot interpret.
///
/// ```swift
/// do {
///   _ = try query.next(after: page)
/// } catch {
///   print(error)  // unexpectedPageNumber(actual: 3, expected: 2)
/// }
/// ```
public enum FoodListPaginationError: Error, Hashable, Sendable {
  /// A page held more foods than its page size allows.
  case excessFoods(count: Int, pageSize: Int)
  /// The following page number does not fit in an `Int`.
  case pageNumberOverflow
  /// The service refused a page past its result window.
  ///
  /// FoodData Central limits how deep a list can page and does not document the limit. The service
  /// answers `400` with the plain-text body "Bad Request: pageSize * pageNumber exceeded upper
  /// search results limit." It was observed at a page number times page size of 200,000; the
  /// exact limit is unknown. ``FoodListQuery/next(after:)`` never throws this case; an executor
  /// reports it when the service refuses a page. The service sends no error code, so the refusal is
  /// recognized by that observed body text, matched exactly; any other `400` is not this case.
  case resultWindowExceeded
  /// The page reports a different page number from the query it answers.
  case unexpectedPageNumber(actual: Int, expected: Int)
  /// The page reports a different page size from the query it answers.
  case unexpectedPageSize(actual: Int, expected: Int)
}
