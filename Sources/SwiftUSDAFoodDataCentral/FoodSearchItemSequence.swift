import SwiftUSDAFoodDataCentralModels

/// Lazy foods from food search, read from the same pages as ``FoodSearchPageSequence``.
///
/// Each iterator fetches one page, yields its foods in the order the service returned them, and
/// fetches the following page only when the current one is exhausted. It holds at most one page
/// and never removes duplicates or reorders foods. Nothing is sent when the sequence or an
/// iterator is created, and breaking out of iteration sends nothing more. Foods yielded before a
/// failure are not a complete set of results.
///
/// A page past the service's result window ends the sequence with
/// `FoodPaginationError.resultWindowExceeded`. The refusal recognized is the plain-text `400`
/// body observed on the food list; the same body is assumed for search, where it has not been
/// recorded.
///
/// ```swift
/// let query = try FoodSearchQuery("cheddar cheese", dataTypes: [.branded], pageSize: 200)
/// for try await food in client.foods(matching: query) {
///   print(food.fdcID, food.description)
/// }
/// ```
public struct FoodSearchItemSequence: AsyncSequence, Sendable {
  /// One search result food, in the service's order.
  public typealias Element = SearchResultFood
  /// The only failure iteration produces.
  public typealias Failure = FoodDataCentralError

  /// An independent traversal of search result foods that reads one page at a time.
  ///
  /// It is not `Sendable`: it is in exclusive use by whichever task reads it.
  public struct Iterator: AsyncIteratorProtocol {
    /// One search result food.
    public typealias Element = SearchResultFood
    /// The same typed failure as page iteration.
    public typealias Failure = FoodDataCentralError

    private var current = [SearchResultFood]().makeIterator()
    private var finished = false
    private var pages: FoodSearchPageSequence.Iterator

    init(pages: FoodSearchPageSequence.Iterator) {
      self.pages = pages
    }

    /// Yields the next food, fetching a page only when the current page is exhausted.
    ///
    /// Cancellation is checked on every read, including while foods remain from the current page.
    /// - Returns: The next food, or `nil` after the last food or any failure.
    /// - Throws: The same ``FoodDataCentralError`` as
    ///   ``FoodSearchPageSequence/Iterator/next(isolation:)``, and
    ///   ``FoodDataCentralError/transport(_:)`` with `TransportError.cancelled` when the reading
    ///   task is cancelled.
    public mutating func next(
      isolation actor: isolated (any Actor)? = #isolation
    ) async throws(FoodDataCentralError) -> SearchResultFood? {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      if let food = current.next() {
        finished = false
        return food
      }
      while let page = try await pages.next(isolation: actor) {
        current = page.foods.makeIterator()
        if let food = current.next() {
          finished = false
          return food
        }
      }
      return nil
    }
  }

  private let pages: FoodSearchPageSequence

  init(pages: FoodSearchPageSequence) {
    self.pages = pages
  }

  /// Creates an iterator that has not sent a request or read a page.
  /// - Returns: An independent traversal starting at the request's first page.
  public func makeAsyncIterator() -> Iterator {
    Iterator(pages: pages.makeAsyncIterator())
  }
}
