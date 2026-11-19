/// The search criteria FoodData Central echoes back with a page of search results.
///
/// Every field is optional and kept as the service sends it: ``sortBy`` and ``sortOrder`` stay
/// strings so an echoed value this package does not name still decodes. Recorded responses echo
/// each filter that was sent, the page number (a requested page 0 is echoed as 1), and
/// ``requireAllWords``; keys the type does not declare, such as the duplicate
/// `generalSearchInput`, are not kept. Continuation uses the query that was sent, never these
/// echoed values.
///
/// ```swift
/// let page = try JSONDecoder().decode(FoodSearchResult.self, from: body)
/// print(page.foodSearchCriteria?.query ?? "")
/// ```
public struct FoodSearchCriteria: Codable, Hashable, Sendable {
  /// The brand owner filter.
  public var brandOwner: String?
  /// The data type filter.
  public var dataType: [FoodDataType]?
  /// The latest publication date, as the service formats it.
  public var endDate: String?
  /// The page number searched.
  public var pageNumber: Int?
  /// The page size searched.
  public var pageSize: Int?
  /// The search terms.
  public var query: String?
  /// Whether every word of the query had to match; recorded responses echo `false`.
  public var requireAllWords: Bool?
  /// The `sortBy` value, as sent on the wire.
  public var sortBy: String?
  /// The `sortOrder` value, as sent on the wire.
  public var sortOrder: String?
  /// The earliest publication date, as the service formats it.
  public var startDate: String?
  /// The trade channel filter.
  public var tradeChannel: [TradeChannel]?

  /// Creates echoed search criteria.
  /// - Parameters:
  ///   - brandOwner: The brand owner filter.
  ///   - dataType: The data type filter.
  ///   - endDate: The latest publication date.
  ///   - pageNumber: The page number searched.
  ///   - pageSize: The page size searched.
  ///   - query: The search terms.
  ///   - requireAllWords: Whether every word of the query had to match.
  ///   - sortBy: The `sortBy` value.
  ///   - sortOrder: The `sortOrder` value.
  ///   - startDate: The earliest publication date.
  ///   - tradeChannel: The trade channel filter.
  public init(
    brandOwner: String? = nil,
    dataType: [FoodDataType]? = nil,
    endDate: String? = nil,
    pageNumber: Int? = nil,
    pageSize: Int? = nil,
    query: String? = nil,
    requireAllWords: Bool? = nil,
    sortBy: String? = nil,
    sortOrder: String? = nil,
    startDate: String? = nil,
    tradeChannel: [TradeChannel]? = nil
  ) {
    self.brandOwner = brandOwner
    self.dataType = dataType
    self.endDate = endDate
    self.pageNumber = pageNumber
    self.pageSize = pageSize
    self.query = query
    self.requireAllWords = requireAllWords
    self.sortBy = sortBy
    self.sortOrder = sortOrder
    self.startDate = startDate
    self.tradeChannel = tradeChannel
  }
}
