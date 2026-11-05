extension FoodRequest where Response == FoodListPage {
  /// One page of the food list, described by its query so the pages after it can follow.
  ///
  /// The request's resolution is ``FoodRequest/Resolution/foodList(_:)``. An executor sends
  /// ``Endpoint/foodList(_:)`` for the query, wraps the returned foods in a ``FoodListPage`` with
  /// the query's page number and size, and continues with ``FoodListQuery/next(after:)``.
  ///
  /// ```swift
  /// let request: FoodRequest<FoodListPage> = .foodList(try FoodListQuery(dataTypes: [.branded]))
  /// ```
  ///
  /// - Parameter query: The validated filters, first page, and sort.
  /// - Returns: A list request.
  public static func foodList(_ query: FoodListQuery) -> Self {
    Self(resolution: .foodList(query))
  }
}
