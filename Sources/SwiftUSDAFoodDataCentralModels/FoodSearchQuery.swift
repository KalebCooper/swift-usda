#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// A validated query for one page of FoodData Central food search, `POST /foods/search`.
///
/// The query text must hold something other than whitespace; it is sent exactly as given and may
/// use FoodData Central's search operators. Every parameter is sent in the JSON request body,
/// including the page number and size. Data types and trade channels are sent as arrays in
/// raw-value order; an empty set sends no filter. Creating a query performs no I/O.
///
/// Pages are numbered from 1. That base was established for the food list, where page 0 returns
/// the same foods as page 1; it is assumed for search and has not been recorded there.
/// ``brandOwner`` is sent exactly as given, with no validation, and applies only to Branded foods.
/// The ``tradeChannels``, ``startDate``, and
/// ``endDate`` filters come from the FoodData Central specification (version 1.0.1), which accepts
/// them only in the request body; they have not been verified against the service.
///
/// ```swift
/// let query = try FoodSearchQuery("cheddar cheese", dataTypes: [.branded], pageSize: 25)
/// let endpoint = Endpoint.foodSearch(query)
/// print(endpoint.method, endpoint.path)  // post /foods/search
/// ```
public struct FoodSearchQuery: Hashable, Sendable {
  /// The largest page size FoodData Central accepts.
  public static let maximumPageSize = 200
  /// The most trade channels one search can filter on, per the specification.
  public static let maximumTradeChannelCount = 3

  /// The brand owner to filter Branded foods by, or `nil` for no brand owner filter.
  ///
  /// It is sent exactly as given, with no validation, and applies only to Branded foods.
  public let brandOwner: String?
  /// The data types to search, or an empty set for every data type.
  public let dataTypes: Set<FoodDataType>
  /// The latest publication date to include, or `nil` for no upper bound.
  public let endDate: FoodPublicationDate?
  /// The one-based page number.
  public let pageNumber: Int
  /// The most foods one page holds, from 1 to ``maximumPageSize``.
  public let pageSize: Int
  /// The search terms, exactly as given.
  public let query: String
  /// The order to return foods in, or `nil` for the service's default order.
  public let sort: FoodSort?
  /// The earliest publication date to include, or `nil` for no lower bound.
  public let startDate: FoodPublicationDate?
  /// The trade channels to filter by, or an empty set for no trade channel filter.
  public let tradeChannels: Set<TradeChannel>

  /// Creates a validated food search query.
  /// - Parameters:
  ///   - query: The search terms, which may use FoodData Central's search operators. Sent exactly
  ///     as given.
  ///   - brandOwner: The brand owner to filter Branded foods by, sent exactly as given with no
  ///     validation. It applies only to Branded foods.
  ///   - dataTypes: The data types to search, or an empty set for every data type.
  ///   - endDate: The latest publication date to include.
  ///   - pageNumber: The one-based page number, 1 or more.
  ///   - pageSize: The most foods one page holds, from 1 to ``maximumPageSize``. FoodData Central
  ///     also defaults to 50.
  ///   - sort: The order to return foods in, or `nil` for the service's default order.
  ///   - startDate: The earliest publication date to include.
  ///   - tradeChannels: The trade channels to filter by, at most ``maximumTradeChannelCount``.
  /// - Throws: ``FoodDataCentralValidationError/emptySearchQuery`` for query text that is empty or
  ///   only whitespace, ``FoodDataCentralValidationError/pageNumber(_:)`` for a page number less
  ///   than 1, ``FoodDataCentralValidationError/pageSize(_:)`` for a page size outside 1 to
  ///   ``maximumPageSize``, ``FoodDataCentralValidationError/tradeChannelCount(_:)`` for more than
  ///   ``maximumTradeChannelCount`` trade channels, and
  ///   ``FoodDataCentralValidationError/publicationDateRange(start:end:)`` for a start date after
  ///   the end date.
  public init(
    // The query text leads, unlabeled, as the one required subject; the options follow in order.
    _ query: String,
    brandOwner: String? = nil,
    dataTypes: Set<FoodDataType> = [],
    endDate: FoodPublicationDate? = nil,
    pageNumber: Int = 1,
    pageSize: Int = 50,
    sort: FoodSort? = nil,
    startDate: FoodPublicationDate? = nil,
    tradeChannels: Set<TradeChannel> = []
  ) throws(FoodDataCentralValidationError) {
    guard query.contains(where: { !$0.isWhitespace }) else { throw .emptySearchQuery }
    guard pageNumber >= 1 else { throw .pageNumber(pageNumber) }
    guard (1...Self.maximumPageSize).contains(pageSize) else { throw .pageSize(pageSize) }
    guard tradeChannels.count <= Self.maximumTradeChannelCount else {
      throw .tradeChannelCount(tradeChannels.count)
    }
    if let startDate, let endDate, endDate < startDate {
      throw .publicationDateRange(start: startDate, end: endDate)
    }
    self.brandOwner = brandOwner
    self.dataTypes = dataTypes
    self.endDate = endDate
    self.pageNumber = pageNumber
    self.pageSize = pageSize
    self.query = query
    self.sort = sort
    self.startDate = startDate
    self.tradeChannels = tradeChannels
  }

  private init(copy: Self, pageNumber: Int) {
    self.brandOwner = copy.brandOwner
    self.dataTypes = copy.dataTypes
    self.endDate = copy.endDate
    self.pageNumber = pageNumber
    self.pageSize = copy.pageSize
    self.query = copy.query
    self.sort = copy.sort
    self.startDate = copy.startDate
    self.tradeChannels = copy.tradeChannels
  }

  /// Checks a received page and describes the query for the page after it, if any.
  ///
  /// The page must answer this query: its ``FoodSearchResult/currentPage`` must equal this
  /// query's page number, it holds no more foods than the page size, and its totals agree with
  /// each other and with the page. While the current page is before
  /// ``FoodSearchResult/totalPages``, the result is this query at the next page number with every
  /// filter and the sort unchanged; on the last page, or when nothing matched, it is `nil`. A page
  /// at or past the reported page count ends the search, including when that count shrinks below
  /// the current page between requests. The
  /// totals are the service's figures for the page received; results can change between requests,
  /// and pages are not a snapshot. The page count is not checked against the hit count and page
  /// size, because FoodData Central does not document how it computes it.
  /// - Parameter page: The page received for this query.
  /// - Returns: The query for the following page, or `nil` when `page` is the last.
  /// - Throws: ``FoodPaginationError/unexpectedPageNumber(actual:expected:)`` for a page that
  ///   reports another page number, including one that repeats an earlier page;
  ///   ``FoodPaginationError/excessFoods(count:pageSize:)`` for a page holding more foods than its
  ///   size; or ``FoodPaginationError/inconsistentTotals(totalHits:totalPages:)`` for a negative
  ///   total, for exactly one of the two totals being zero, or for more foods than the total hits.
  public func next(after page: FoodSearchResult) throws(FoodPaginationError) -> Self? {
    guard page.currentPage == pageNumber else {
      throw .unexpectedPageNumber(actual: page.currentPage, expected: pageNumber)
    }
    guard page.foods.count <= pageSize else {
      throw .excessFoods(count: page.foods.count, pageSize: pageSize)
    }
    guard page.totalHits >= 0, page.totalPages >= 0,
      (page.totalHits == 0) == (page.totalPages == 0),
      page.foods.count <= page.totalHits
    else { throw .inconsistentTotals(totalHits: page.totalHits, totalPages: page.totalPages) }
    guard page.currentPage < page.totalPages else { return nil }
    // The page number is less than the page count, an `Int`, so one more cannot overflow.
    return Self(copy: self, pageNumber: pageNumber + 1)
  }

  // The UTF-8 JSON body for this page: sorted keys, unescaped slashes, absent options omitted, and
  // both sets sent in raw-value order, so one query always encodes to the same bytes.
  var requestBody: Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    guard let body = try? encoder.encode(SearchRequestBody(self)) else {
      preconditionFailure("Every search body field is a String, an Int, or a String array.")
    }
    return body
  }
}

// The search request body's wire spellings live only here.
private struct SearchRequestBody: Encodable {
  let brandOwner: String?
  let dataType: [String]?
  let endDate: String?
  let pageNumber: Int
  let pageSize: Int
  let query: String
  let sortBy: String?
  let sortOrder: String?
  let startDate: String?
  let tradeChannel: [String]?

  init(_ query: FoodSearchQuery) {
    self.brandOwner = query.brandOwner
    self.dataType =
      query.dataTypes.isEmpty ? nil : query.dataTypes.map(\.rawValue).sorted()
    self.endDate = query.endDate?.description
    self.pageNumber = query.pageNumber
    self.pageSize = query.pageSize
    self.query = query.query
    self.sortBy = query.sort?.field.rawValue
    self.sortOrder = query.sort?.order?.rawValue
    self.startDate = query.startDate?.description
    self.tradeChannel =
      query.tradeChannels.isEmpty ? nil : query.tradeChannels.map(\.rawValue).sorted()
  }
}
