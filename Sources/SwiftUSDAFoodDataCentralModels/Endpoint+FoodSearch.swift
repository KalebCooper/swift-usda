extension Endpoint where Response == FoodSearchResult {
  /// One page of food search results, `POST /foods/search` with the query as a JSON body.
  ///
  /// The body carries every parameter, including the filters the specification accepts only in a
  /// body. It is encoded with sorted keys and unescaped slashes, so one query always produces the
  /// same bytes. The order is the query's sort, or the service's undocumented relevance order
  /// without one.
  ///
  /// ```swift
  /// let endpoint = Endpoint.foodSearch(try FoodSearchQuery("cheddar cheese", pageSize: 25))
  /// print(String(decoding: endpoint.body ?? Data(), as: UTF8.self))
  /// // {"pageNumber":1,"pageSize":25,"query":"cheddar cheese"}
  /// ```
  ///
  /// - Parameter query: The validated search terms, filters, page, and sort.
  /// - Returns: A POST endpoint with a JSON body.
  public static func foodSearch(_ query: FoodSearchQuery) -> Self {
    builtIn(path: "/foods/search", postingJSON: query.requestBody)
  }
}
