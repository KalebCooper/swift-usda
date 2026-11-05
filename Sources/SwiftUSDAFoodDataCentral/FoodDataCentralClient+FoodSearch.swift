#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import SwiftUSDAFoodDataCentralModels

extension FoodDataCentralClient {
  /// Lazily searches foods page by page, starting at the query's page.
  ///
  /// Sends `FoodRequest.foodSearch(_:)` through `pages(for:)`. Nothing is sent until the
  /// sequence is read, and each page after the first posts the query at the next page number, with
  /// the same search terms, filters, page size, and sort.
  ///
  /// ```swift
  /// for try await page in client.foodSearchPages(try FoodSearchQuery("cheddar cheese")) {
  ///   print(page.currentPage, page.totalPages, page.foods.count)
  /// }
  /// ```
  ///
  /// - Parameter query: The validated search terms, filters, first page, and sort.
  /// - Returns: The pages, as a ``FoodSearchPageSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func foodSearchPages(_ query: FoodSearchQuery) -> FoodSearchPageSequence {
    pages(for: .foodSearch(query))
  }

  /// Lazily searches foods one at a time, starting at the query's page.
  ///
  /// Sends `FoodRequest.foodSearch(_:)` through `items(for:)`, yielding every food of
  /// ``foodSearchPages(_:)`` in the same order.
  ///
  /// ```swift
  /// for try await food in client.foods(matching: try FoodSearchQuery("apple")) {
  ///   print(food.description)
  /// }
  /// ```
  ///
  /// - Parameter query: The validated search terms, filters, first page, and sort.
  /// - Returns: The foods, as a ``FoodSearchItemSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func foods(matching query: FoodSearchQuery) -> FoodSearchItemSequence {
    items(for: .foodSearch(query))
  }

  /// Lazily reads the foods of a search request, one at a time.
  ///
  /// The foods come from `pages(for:)` for the same request, in page order and then in the
  /// order the service returned them.
  /// - Parameter request: The search request to traverse.
  /// - Returns: The foods, as a ``FoodSearchItemSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func items(for request: FoodRequest<FoodSearchResult>) -> FoodSearchItemSequence {
    FoodSearchItemSequence(pages: pages(for: request))
  }

  /// Lazily reads the pages of a search request without sending anything at construction.
  ///
  /// A `FoodRequest.foodSearch(_:)` request posts `Endpoint.foodSearch(_:)` for its query and
  /// continues with `FoodSearchQuery.next(after:)` until the last reported page. A request made
  /// with `FoodRequest.init(endpoint:)` declares no continuation, so it yields only its one page,
  /// decoded as ``send(_:)`` decodes it. Every request carries the API key in the `X-Api-Key`
  /// header.
  ///
  /// ```swift
  /// let request: FoodRequest<FoodSearchResult> = .foodSearch(try FoodSearchQuery("apple"))
  /// for try await page in client.pages(for: request) {
  ///   print(page.foods.count)
  /// }
  /// ```
  ///
  /// - Parameter request: The search request to traverse.
  /// - Returns: The pages, as a ``FoodSearchPageSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func pages(for request: FoodRequest<FoodSearchResult>) -> FoodSearchPageSequence {
    switch request.resolution {
    case .endpoint(let endpoint):
      let pages = client.pages(self.request(for: endpoint), as: FoodSearchResult.self) { _, _ in
        nil
      }
      return FoodSearchPageSequence(.endpoint(pages))
    case .foodSearch(let query):
      let pages = client.pages(
        self.request(for: Endpoint.foodSearch(query)), as: FoodSearchResult.self
      ) { page, sent in
        // The callback cannot throw; the iterator checks each page with the same rule and reports
        // a failure before yielding it.
        guard let current = Self.searchQuery(query, sentAs: sent),
          let following = try? current.next(after: page.value)
        else { return nil }
        return .request(self.request(for: Endpoint.foodSearch(following)))
      }
      return FoodSearchPageSequence(.foodSearch(pages, query))
    case .foodList:
      preconditionFailure("Only FoodRequest<FoodListPage> can hold a food list resolution.")
    }
  }

  // The query a sent search request was rendered from: the traversal's query at the page number in
  // its body, accepted only when it renders back to exactly that body.
  private static func searchQuery(
    _ start: FoodSearchQuery, sentAs sent: Request
  ) -> FoodSearchQuery? {
    guard case .bytes(let body, _) = sent.body,
      let number = try? JSONDecoder().decode(SentSearchPage.self, from: body).pageNumber,
      let current = try? FoodSearchQuery(
        start.query, brandOwner: start.brandOwner, dataTypes: start.dataTypes,
        endDate: start.endDate, pageNumber: number, pageSize: start.pageSize, sort: start.sort,
        startDate: start.startDate, tradeChannels: start.tradeChannels),
      Endpoint.foodSearch(current).body == body
    else { return nil }
    return current
  }
}

// The one field of a sent search body that changes from page to page.
private struct SentSearchPage: Decodable {
  let pageNumber: Int
}
