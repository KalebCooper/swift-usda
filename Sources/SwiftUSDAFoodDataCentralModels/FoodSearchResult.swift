/// One page of food search results, with the totals FoodData Central reports for the search.
///
/// The service answers `/foods/search` with one object, as the FoodData Central specification
/// (version 1.0.1) types it; version 1.0.0 types it as an array. The specification marks no field
/// as required; this type requires the page number, both totals, and the foods, because
/// continuing a search depends on them. The response's `aggregations` and `pageList` keys are not
/// kept. The echoed ``foodSearchCriteria`` is decoded leniently: an echo of another shape becomes
/// `nil` rather than failing the page, because continuation never reads it. Pass a page to
/// ``FoodSearchQuery/next(after:)`` to describe the following page.
///
/// ```swift
/// let page = try JSONDecoder().decode(FoodSearchResult.self, from: body)
/// print(page.currentPage, page.totalPages, page.totalHits)
/// if let following = try query.next(after: page) {
///   print(following.pageNumber)
/// }
/// ```
public struct FoodSearchResult: Codable, Hashable, Sendable {
  /// The one-based page number the service reports for this page.
  public var currentPage: Int
  /// The criteria the service reports it searched with, or `nil` when it sends none or sends an
  /// echo that does not decode as ``FoodSearchCriteria``.
  ///
  /// Continuation never reads this echo; ``FoodSearchQuery/next(after:)`` continues from the query
  /// that was sent.
  public var foodSearchCriteria: FoodSearchCriteria?
  /// The page's foods, in the order the service returned them.
  public var foods: [SearchResultFood]
  /// The number of foods matching the search, as the service reports it.
  public var totalHits: Int
  /// The number of pages matching the search, as the service reports it.
  public var totalPages: Int

  /// Creates a search results page.
  /// - Parameters:
  ///   - currentPage: The one-based page number.
  ///   - foodSearchCriteria: The criteria the service reports it searched with.
  ///   - foods: The page's foods.
  ///   - totalHits: The number of matching foods.
  ///   - totalPages: The number of matching pages.
  public init(
    currentPage: Int,
    foodSearchCriteria: FoodSearchCriteria? = nil,
    foods: [SearchResultFood],
    totalHits: Int,
    totalPages: Int
  ) {
    self.currentPage = currentPage
    self.foodSearchCriteria = foodSearchCriteria
    self.foods = foods
    self.totalHits = totalHits
    self.totalPages = totalPages
  }

  /// Decodes a page, reading the echoed criteria leniently.
  /// - Parameter decoder: The decoder to read.
  /// - Throws: `DecodingError` when `currentPage`, `foods`, `totalHits`, or `totalPages` is
  ///   missing or has another shape. A malformed `foodSearchCriteria` never throws.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    currentPage = try container.decode(Int.self, forKey: .currentPage)
    foodSearchCriteria = try? container.decodeIfPresent(
      FoodSearchCriteria.self, forKey: .foodSearchCriteria)
    foods = try container.decode([SearchResultFood].self, forKey: .foods)
    totalHits = try container.decode(Int.self, forKey: .totalHits)
    totalPages = try container.decode(Int.self, forKey: .totalPages)
  }

  enum CodingKeys: String, CodingKey {
    case currentPage
    case foodSearchCriteria
    case foods
    case totalHits
    case totalPages
  }
}
