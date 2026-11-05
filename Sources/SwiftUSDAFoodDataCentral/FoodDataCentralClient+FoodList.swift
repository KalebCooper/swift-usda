#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import SwiftUSDAFoodDataCentralModels

extension FoodDataCentralClient {
  /// Lazily lists foods page by page, starting at the query's page.
  ///
  /// Sends `FoodRequest.foodList(_:)` through ``pages(for:)``. Nothing is sent until the sequence
  /// is read, and each page after the first is the query at the next page number, with the same
  /// data types, page size, and sort.
  ///
  /// ```swift
  /// for try await page in client.foodListPages(try FoodListQuery(dataTypes: [.foundation])) {
  ///   print(page.pageNumber, page.foods.count)
  /// }
  /// ```
  ///
  /// - Parameter query: The validated filters, first page, and sort.
  /// - Returns: The pages, as a ``FoodListPageSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func foodListPages(_ query: FoodListQuery) -> FoodListPageSequence {
    pages(for: .foodList(query))
  }

  /// Lazily lists foods one at a time, starting at the query's page.
  ///
  /// Sends `FoodRequest.foodList(_:)` through ``items(for:)``, yielding every food of
  /// ``foodListPages(_:)`` in the same order.
  ///
  /// ```swift
  /// for try await food in client.foods(listing: try FoodListQuery(dataTypes: [.srLegacy])) {
  ///   print(food.description)
  /// }
  /// ```
  ///
  /// - Parameter query: The validated filters, first page, and sort.
  /// - Returns: The foods, as a ``FoodListItemSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func foods(listing query: FoodListQuery) -> FoodListItemSequence {
    items(for: .foodList(query))
  }

  /// Lazily reads the foods of a list request, one at a time.
  ///
  /// The foods come from ``pages(for:)`` for the same request, in page order and then in the
  /// order the service returned them.
  /// - Parameter request: The list request to traverse.
  /// - Returns: The foods, as a ``FoodListItemSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func items(for request: FoodRequest<FoodListPage>) -> FoodListItemSequence {
    FoodListItemSequence(pages: pages(for: request))
  }

  /// Lazily reads the pages of a list request without sending anything at construction.
  ///
  /// A `FoodRequest.foodList(_:)` request sends `Endpoint.foodList(_:)` for its query and
  /// continues with `FoodListQuery.next(after:)` until a short or empty page. A request made with
  /// `FoodRequest.init(endpoint:)` declares no continuation, so it yields only its one page,
  /// decoded as ``send(_:)`` decodes it. A real `/foods/list` response is a bare array that cannot
  /// decode as `FoodListPage`, so list foods with `Endpoint<[AbridgedFood]>` or
  /// `FoodRequest.foodList(_:)`. Every request carries the API key in the `X-Api-Key` header.
  ///
  /// ```swift
  /// let request: FoodRequest<FoodListPage> = .foodList(try FoodListQuery(pageSize: 200))
  /// for try await page in client.pages(for: request) {
  ///   print(page.foods.count)
  /// }
  /// ```
  ///
  /// - Parameter request: The list request to traverse.
  /// - Returns: The pages, as a ``FoodListPageSequence`` whose reads throw
  ///   ``FoodDataCentralError``.
  public func pages(for request: FoodRequest<FoodListPage>) -> FoodListPageSequence {
    switch request.resolution {
    case .endpoint(let endpoint):
      let pages = client.pages(self.request(for: endpoint), as: FoodListPage.self) { _, _ in nil }
      return FoodListPageSequence(.endpoint(pages))
    case .foodList(let query):
      let pages = client.pages(
        self.request(for: Endpoint.foodList(query)), as: [AbridgedFood].self
      ) { page, sent in
        // The callback cannot throw; the iterator checks each page with the same rule and reports
        // a failure before yielding it.
        guard let current = Self.listQuery(query, sentAs: sent),
          let following = try? current.next(
            after: FoodListPage(
              foods: page.value, pageNumber: current.pageNumber, pageSize: current.pageSize))
        else { return nil }
        return .request(self.request(for: Endpoint.foodList(following)))
      }
      return FoodListPageSequence(.foodList(pages, query))
    }
  }

  /// Fetches one page of the food list.
  ///
  /// A `FoodRequest.foodList(_:)` request sends `Endpoint.foodList(_:)` for its query and wraps
  /// the returned foods in a `FoodListPage` with the query's page number and size. A request made
  /// with `FoodRequest.init(endpoint:)` sends that endpoint and decodes its body as a
  /// `FoodListPage`. Only the one page is fetched; continue with ``pages(for:)`` or
  /// `FoodListQuery.next(after:)`.
  /// - Parameter request: The list request to execute.
  /// - Returns: The page, in the order the service returned its foods.
  /// - Throws: ``FoodDataCentralError/gateway(_:response:)`` for gateway errors, or
  ///   ``FoodDataCentralError/transport(_:)`` for a rejected request (`400`), including a page
  ///   past the service's result window, other HTTP, decoding, connection, and cancellation
  ///   failures.
  public func value(
    for request: FoodRequest<FoodListPage>
  ) async throws(FoodDataCentralError) -> FoodListPage {
    switch request.resolution {
    case .endpoint(let endpoint):
      return try await send(endpoint)
    case .foodList(let query):
      return try await foodListPage(query)
    }
  }

  func foodListPage(_ query: FoodListQuery) async throws(FoodDataCentralError) -> FoodListPage {
    let foods = try await send(Endpoint.foodList(query))
    return FoodListPage(foods: foods, pageNumber: query.pageNumber, pageSize: query.pageSize)
  }

  // The query a sent list request was rendered from: the traversal's query at the page number in
  // its path, accepted only when it renders back to exactly that path.
  private static func listQuery(_ start: FoodListQuery, sentAs sent: Request) -> FoodListQuery? {
    guard
      let raw = URLComponents(string: sent.path)?.queryItems?
        .first(where: { $0.name == "pageNumber" })?.value,
      let number = Int(raw),
      let current = try? FoodListQuery(
        dataTypes: start.dataTypes, pageNumber: number, pageSize: start.pageSize, sort: start.sort),
      Endpoint.foodList(current).path == sent.path
    else { return nil }
    return current
  }
}
