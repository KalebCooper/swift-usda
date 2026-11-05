/// A validated query for one page of FoodData Central's food list, `GET /foods/list`.
///
/// Pages are numbered from 1; the service treats page 0 as page 1, so 0 is rejected rather than
/// fetching the first page twice. Every parameter is sent explicitly, including the page number
/// and size. Data types are sent comma-separated in raw-value order; an empty set sends no filter,
/// so every data type is listed. Creating a query performs no I/O.
///
/// FoodData Central limits how deep a list can page and does not document the limit; see
/// ``FoodPaginationError/resultWindowExceeded``.
///
/// ```swift
/// let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 100)
/// let endpoint = Endpoint.foodList(query)
/// print(endpoint.path)  // "/foods/list?dataType=Foundation&pageNumber=1&pageSize=100"
/// ```
public struct FoodListQuery: Hashable, Sendable {
  /// The largest page size FoodData Central accepts.
  public static let maximumPageSize = 200

  /// The data types to list, or an empty set for every data type.
  public let dataTypes: Set<FoodDataType>
  /// The one-based page number.
  public let pageNumber: Int
  /// The most foods one page holds, from 1 to ``maximumPageSize``.
  public let pageSize: Int
  /// The order to list foods in, or `nil` for the service's default order.
  public let sort: FoodSort?

  /// Creates a validated food list query.
  /// - Parameters:
  ///   - dataTypes: The data types to list, or an empty set for every data type.
  ///   - pageNumber: The one-based page number, 1 or more.
  ///   - pageSize: The most foods one page holds, from 1 to ``maximumPageSize``. FoodData Central
  ///     also defaults to 50.
  ///   - sort: The order to list foods in, or `nil` for the service's default order.
  /// - Throws: ``FoodDataCentralValidationError/pageNumber(_:)`` for a page number less than 1,
  ///   and ``FoodDataCentralValidationError/pageSize(_:)`` for a page size outside 1 to
  ///   ``maximumPageSize``.
  public init(
    dataTypes: Set<FoodDataType> = [], pageNumber: Int = 1, pageSize: Int = 50,
    sort: FoodSort? = nil
  ) throws(FoodDataCentralValidationError) {
    guard pageNumber >= 1 else { throw .pageNumber(pageNumber) }
    guard (1...Self.maximumPageSize).contains(pageSize) else { throw .pageSize(pageSize) }
    self.dataTypes = dataTypes
    self.pageNumber = pageNumber
    self.pageSize = pageSize
    self.sort = sort
  }

  private init(copy: Self, pageNumber: Int) {
    self.dataTypes = copy.dataTypes
    self.pageNumber = pageNumber
    self.pageSize = copy.pageSize
    self.sort = copy.sort
  }

  /// Checks a received page and describes the query for the page after it, if any.
  ///
  /// The page must answer this query: the same page number and size, with no more foods than the
  /// page size. A page with fewer foods than the page size, including an empty page, ends the list.
  /// FoodData Central sends no total, so this is the SDK's reading of a short page, not a
  /// guarantee from the service; a list whose length is a multiple of the page size ends with one
  /// empty page. Otherwise the result is this query at the next page number, with the same data
  /// types, page size, and sort. The list can change between requests; pages are not a snapshot.
  /// - Parameter page: The page received for this query.
  /// - Returns: The query for the following page, or `nil` when `page` is the last.
  /// - Throws: ``FoodPaginationError/unexpectedPageNumber(actual:expected:)`` or
  ///   ``FoodPaginationError/unexpectedPageSize(actual:expected:)`` for a page that answers a
  ///   different query, ``FoodPaginationError/excessFoods(count:pageSize:)`` for a page holding
  ///   more foods than its size, and ``FoodPaginationError/pageNumberOverflow`` when the next
  ///   page number does not fit in an `Int`.
  public func next(after page: FoodListPage) throws(FoodPaginationError) -> Self? {
    guard page.pageNumber == pageNumber else {
      throw .unexpectedPageNumber(actual: page.pageNumber, expected: pageNumber)
    }
    guard page.pageSize == pageSize else {
      throw .unexpectedPageSize(actual: page.pageSize, expected: pageSize)
    }
    guard page.foods.count <= pageSize else {
      throw .excessFoods(count: page.foods.count, pageSize: pageSize)
    }
    guard page.foods.count == pageSize else { return nil }
    let (following, overflow) = pageNumber.addingReportingOverflow(1)
    guard !overflow else { throw .pageNumberOverflow }
    return Self(copy: self, pageNumber: following)
  }

  // Every parameter for this page, in parameter-name order, unencoded.
  var queryItems: [(name: String, value: String)] {
    var items: [(name: String, value: String)] = []
    if !dataTypes.isEmpty {
      items.append(("dataType", dataTypes.map(\.rawValue).sorted().joined(separator: ",")))
    }
    items.append(("pageNumber", String(pageNumber)))
    items.append(("pageSize", String(pageSize)))
    if let sort {
      items.append(("sortBy", sort.field.rawValue))
      if let order = sort.order { items.append(("sortOrder", order.rawValue)) }
    }
    return items
  }
}
