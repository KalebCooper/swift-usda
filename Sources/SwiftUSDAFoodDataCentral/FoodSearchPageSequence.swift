import HTTPCore
import SwiftUSDAFoodDataCentralModels

/// Lazy pages of food search results, fetched one at a time through swifty-networking's pagination.
///
/// Nothing is sent when the sequence or an iterator is created. Each read posts one search page,
/// with no prefetch, and each iterator starts its own traversal from the request's first page.
/// Breaking out of iteration sends nothing more.
///
/// A search request continues with `FoodSearchQuery.next(after:)`, preserving its search terms,
/// filters, page size, and sort, until the page whose `currentPage` reaches or passes the reported
/// `totalPages`; a page count that shrinks below the current page ends the search after that page.
/// A search that matches nothing yields one empty page and ends. The totals are the
/// service's figures for each page received; results can change between requests, and pages are
/// not a snapshot. A request made with `FoodRequest.init(endpoint:)` declares no continuation and
/// yields only its one page.
///
/// A page the service refuses as past its result window ends the sequence with
/// `FoodPaginationError.resultWindowExceeded`. The refusal recognized is the plain-text `400`
/// body the food list sends. No search refusal has been observed (search pages at a page number
/// times page size of 10,002 were answered normally), so the search window is unknown.
///
/// A start page past the last answers with page 1 and no foods; that page is not yielded, and the
/// sequence fails with `FoodPaginationError.unexpectedPageNumber(actual:expected:)`.
///
/// Any failure ends the iterator, and every later read returns `nil`. A page whose continuation
/// cannot be checked is not yielded.
///
/// ```swift
/// let query = try FoodSearchQuery("cheddar cheese", dataTypes: [.branded], pageSize: 200)
/// for try await page in client.foodSearchPages(query) {
///   print(page.currentPage, page.totalPages, page.foods.count)
/// }
/// ```
public struct FoodSearchPageSequence: AsyncSequence, Sendable {
  /// One page of food search results.
  public typealias Element = FoodSearchResult
  /// The only failure iteration produces.
  public typealias Failure = FoodDataCentralError

  /// An independent traversal of food search pages that holds the query for its next page.
  ///
  /// It is not `Sendable`: it is in exclusive use by whichever task reads it.
  public struct Iterator: AsyncIteratorProtocol {
    /// One page of food search results.
    public typealias Element = FoodSearchResult
    /// The typed gateway, transport, cancellation, or pagination failure.
    public typealias Failure = FoodDataCentralError

    private var finished = false
    private var pages: PageSequence<FoodSearchResult>.Iterator
    // The query for the next page of a search traversal; always `nil` for an endpoint request.
    private var query: FoodSearchQuery?

    init(_ base: Base) {
      switch base {
      case .endpoint(let pages):
        self.pages = pages.makeAsyncIterator()
        self.query = nil
      case .foodSearch(let pages, let query):
        self.pages = pages.makeAsyncIterator()
        self.query = query
      }
    }

    /// Fetches and checks the next page, or returns `nil` after the last page or any failure.
    ///
    /// Cancellation is checked before the page is requested and again before it is returned.
    /// - Returns: The next page, in the order the service returned its foods.
    /// - Throws: ``FoodDataCentralError/pagination(_:)`` with
    ///   `FoodPaginationError.resultWindowExceeded` when the service refuses a page past its
    ///   result window, `FoodPaginationError.unexpectedPageNumber(actual:expected:)` for a page
    ///   reporting another page number, `FoodPaginationError.excessFoods(count:pageSize:)` for a
    ///   page holding more foods than its size, and
    ///   `FoodPaginationError.inconsistentTotals(totalHits:totalPages:)` for totals that
    ///   contradict each other or the page, none of which yields the page;
    ///   ``FoodDataCentralError/gateway(_:response:)`` for gateway errors; and
    ///   ``FoodDataCentralError/transport(_:)`` for other HTTP, decoding, connection, and
    ///   cancellation failures.
    public mutating func next(
      isolation actor: isolated (any Actor)? = #isolation
    ) async throws(FoodDataCentralError) -> FoodSearchResult? {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      let response: DecodedResponse<FoodSearchResult>?
      do throws(TransportError) {
        response = try await pages.next(isolation: actor)
      } catch {
        throw .paging(error)
      }
      guard let query else {
        guard !Task.isCancelled else { throw .transport(.cancelled) }
        return response?.value
      }
      guard let response else {
        preconditionFailure(
          "The base sequence ends only where query.next(after:) returns nil or throws.")
      }
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      do throws(FoodPaginationError) {
        self.query = try query.next(after: response.value)
      } catch {
        throw .pagination(error)
      }
      finished = self.query == nil
      return response.value
    }
  }

  // The swifty-networking page sequence behind one request: a consumer endpoint, or the search
  // endpoint with the query that starts the traversal.
  enum Base: Sendable {
    case endpoint(PageSequence<FoodSearchResult>)
    case foodSearch(PageSequence<FoodSearchResult>, FoodSearchQuery)
  }

  private let base: Base

  init(_ base: Base) {
    self.base = base
  }

  /// Creates an iterator that has not sent a request.
  /// - Returns: An independent traversal starting at the request's first page.
  public func makeAsyncIterator() -> Iterator {
    Iterator(base)
  }
}
