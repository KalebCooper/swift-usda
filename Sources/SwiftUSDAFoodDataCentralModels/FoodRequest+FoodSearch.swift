extension FoodRequest where Response == FoodSearchResult {
  /// One page of food search results, described by its query so the pages after it can follow.
  ///
  /// The request's resolution is ``FoodRequest/Resolution/foodSearch(_:)``. An executor sends
  /// ``Endpoint/foodSearch(_:)`` for the query, decodes the ``FoodSearchResult``, and continues
  /// with ``FoodSearchQuery/next(after:)``.
  ///
  /// ```swift
  /// let request: FoodRequest<FoodSearchResult> = .foodSearch(try FoodSearchQuery("apple"))
  /// ```
  ///
  /// - Parameter query: The validated search terms, filters, first page, and sort.
  /// - Returns: A search request.
  public static func foodSearch(_ query: FoodSearchQuery) -> Self {
    Self(resolution: .foodSearch(query))
  }
}
