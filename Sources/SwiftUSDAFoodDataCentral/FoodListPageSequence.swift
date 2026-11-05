import HTTPCore
import SwiftUSDAFoodDataCentralModels

/// Lazy pages of the food list, fetched one at a time through swifty-networking's pagination.
///
/// Nothing is sent when the sequence or an iterator is created. Each read fetches one page, with
/// no prefetch, and each iterator starts its own traversal from the request's first page. A page
/// is a `FoodListPage`: the bare array the service sends, paired with the page number and size
/// that were requested. Breaking out of iteration sends nothing more.
///
/// A list request continues with `FoodListQuery.next(after:)`, preserving its data types, page
/// size, and sort. A page with fewer foods than the page size, including an empty page, is the
/// last; FoodData Central sends no total, so this is the SDK's reading of a short page, not a
/// guarantee from the service, and a list whose length is a multiple of the page size ends with
/// one extra, empty page. The list can change between requests; pages are not a snapshot. A
/// request made with `FoodRequest.init(endpoint:)` declares no continuation and yields only its
/// one page.
///
/// Any failure ends the iterator, and every later read returns `nil`. A page whose continuation
/// cannot be checked is not yielded.
///
/// ```swift
/// let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 200)
/// for try await page in client.foodListPages(query) {
///   print(page.pageNumber, page.foods.count)
/// }
/// ```
public struct FoodListPageSequence: AsyncSequence, Sendable {
  /// One page of the food list.
  public typealias Element = FoodListPage
  /// The only failure iteration produces.
  public typealias Failure = FoodDataCentralError

  /// An independent traversal of food list pages that holds the query for its next page.
  ///
  /// It is not `Sendable`: it is in exclusive use by whichever task reads it.
  public struct Iterator: AsyncIteratorProtocol {
    /// One page of the food list.
    public typealias Element = FoodListPage
    /// The typed gateway, transport, cancellation, or pagination failure.
    public typealias Failure = FoodDataCentralError

    private var base: Base.Pages
    private var finished = false
    private var query: FoodListQuery?

    init(_ base: Base) {
      switch base {
      case .endpoint(let pages):
        self.base = .endpoint(pages.makeAsyncIterator())
        self.query = nil
      case .foodList(let pages, let query):
        self.base = .foodList(pages.makeAsyncIterator())
        self.query = query
      }
    }

    /// Fetches and checks the next page, or returns `nil` after the last page or any failure.
    ///
    /// Cancellation is checked before the page is requested and again before it is returned.
    /// - Returns: The next page, in the order the service returned its foods.
    /// - Throws: ``FoodDataCentralError/pagination(_:)`` with
    ///   `FoodPaginationError.resultWindowExceeded` when the service refuses a page past its
    ///   result window, `FoodPaginationError.excessFoods(count:pageSize:)` for a page holding
    ///   more foods than its size, and `FoodPaginationError.pageNumberOverflow` when the next
    ///   page number does not fit in an `Int`, none of which yields the page;
    ///   ``FoodDataCentralError/gateway(_:response:)`` for gateway errors; and
    ///   ``FoodDataCentralError/transport(_:)`` for other HTTP, decoding, connection, and
    ///   cancellation failures.
    public mutating func next(
      isolation actor: isolated (any Actor)? = #isolation
    ) async throws(FoodDataCentralError) -> FoodListPage? {
      guard !finished else { return nil }
      finished = true
      guard !Task.isCancelled else { throw .transport(.cancelled) }
      switch base {
      case .endpoint(var pages):
        let response: DecodedResponse<FoodListPage>?
        do throws(TransportError) {
          response = try await pages.next(isolation: actor)
        } catch {
          throw .paging(error)
        }
        base = .endpoint(pages)
        guard !Task.isCancelled else { throw .transport(.cancelled) }
        return response?.value
      case .foodList(var pages):
        guard let query else {
          preconditionFailure("A food list iterator holds a query until its traversal ends.")
        }
        let response: DecodedResponse<[AbridgedFood]>?
        do throws(TransportError) {
          response = try await pages.next(isolation: actor)
        } catch {
          throw .paging(error)
        }
        base = .foodList(pages)
        guard let response else {
          preconditionFailure(
            "The base sequence ends only where query.next(after:) returns nil or throws.")
        }
        guard !Task.isCancelled else { throw .transport(.cancelled) }
        let page = FoodListPage(
          foods: response.value, pageNumber: query.pageNumber, pageSize: query.pageSize)
        do throws(FoodPaginationError) {
          self.query = try query.next(after: page)
        } catch {
          throw .pagination(error)
        }
        finished = self.query == nil
        return page
      }
    }
  }

  // The swifty-networking page sequence behind one request: a consumer endpoint decoded as a page,
  // or the list endpoint's bare arrays with the query that starts the traversal.
  enum Base: Sendable {
    case endpoint(PageSequence<FoodListPage>)
    case foodList(PageSequence<[AbridgedFood]>, FoodListQuery)

    enum Pages {
      case endpoint(PageSequence<FoodListPage>.Iterator)
      case foodList(PageSequence<[AbridgedFood]>.Iterator)
    }
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
