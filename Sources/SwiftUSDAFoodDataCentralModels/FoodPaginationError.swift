/// Why a food list or food search cannot safely continue to another page.
///
/// ``FoodListQuery/next(after:)`` and ``FoodSearchQuery/next(after:)`` throw the page-checking cases
/// rather than guess a successor, so a traversal never ends quietly on a page it cannot interpret.
/// Each case's documentation says which traversal reports it.
///
/// ```swift
/// do {
///   _ = try query.next(after: page)
/// } catch {
///   print(error)  // unexpectedPageNumber(actual: 3, expected: 2)
/// }
/// ```
public enum FoodPaginationError: Error, Hashable, Sendable {
  /// A page held more foods than its page size allows.
  ///
  /// Both ``FoodListQuery/next(after:)`` and ``FoodSearchQuery/next(after:)`` throw this case.
  case excessFoods(count: Int, pageSize: Int)
  /// A search page reported totals that contradict each other or the page.
  ///
  /// Only ``FoodSearchQuery/next(after:)`` throws this case: for a negative total, for exactly one
  /// of the two totals being zero, or for a page holding more foods than its total hits.
  case inconsistentTotals(totalHits: Int, totalPages: Int)
  /// The following page number does not fit in an `Int`.
  ///
  /// Only ``FoodListQuery/next(after:)`` throws this case. A search continues only while its page
  /// number is below the reported page count, so its next page number always fits.
  case pageNumberOverflow
  /// The service refused a page past its result window.
  ///
  /// FoodData Central limits how deep results can page and does not document the limit. The
  /// service answers `400` with the plain-text body "Bad Request: pageSize * pageNumber exceeded
  /// upper search results limit." It was observed on the food list at a page number times page
  /// size of 200,000; the exact limit is unknown. Neither `next(after:)` throws this case; an
  /// executor reports it when the service refuses a page. The service sends no error code, so the
  /// refusal is recognized by that observed body text, matched exactly; any other `400` is not this
  /// case.
  case resultWindowExceeded
  /// The page reports a different page number from the query it answers.
  ///
  /// Both ``FoodListQuery/next(after:)`` and ``FoodSearchQuery/next(after:)`` throw this case; for a
  /// search it is how a page that repeats an earlier page number, and so makes no progress, is
  /// reported.
  case unexpectedPageNumber(actual: Int, expected: Int)
  /// The page reports a different page size from the query it answers.
  ///
  /// Only ``FoodListQuery/next(after:)`` throws this case; a search page reports no page size of
  /// its own.
  case unexpectedPageSize(actual: Int, expected: Int)
}
