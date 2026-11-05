/// The search criteria FoodData Central echoes back with a page of search results.
///
/// Every field is optional and kept as the service sends it: ``sortBy`` and ``sortOrder`` stay
/// strings so an echoed value this package does not name still decodes. The shape follows the
/// FoodData Central specification (version 1.0.1) and has not been verified against a recorded
/// response; fields the specification does not list are not kept. Continuation uses the query that
/// was sent, never these echoed values.
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
    self.sortBy = sortBy
    self.sortOrder = sortOrder
    self.startDate = startDate
    self.tradeChannel = tradeChannel
  }
}
