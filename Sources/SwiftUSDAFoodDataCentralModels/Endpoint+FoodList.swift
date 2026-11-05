extension Endpoint where Response == [AbridgedFood] {
  /// One page of the food list, `GET /foods/list`, as the bare array the service sends.
  ///
  /// Every food arrives in the abridged format. The array carries no page number or total; wrap
  /// it in a ``FoodListPage`` with the query's page number and size to continue with
  /// ``FoodListQuery/next(after:)``. The order is the query's sort, or the service's undocumented
  /// default without one.
  ///
  /// ```swift
  /// let query = try FoodListQuery(
  ///   dataTypes: [.foundation], pageSize: 2, sort: FoodSort(field: .fdcID, order: .descending))
  /// Endpoint.foodList(query).path
  /// // "/foods/list?dataType=Foundation&pageNumber=1&pageSize=2&sortBy=fdcId&sortOrder=desc"
  /// ```
  ///
  /// - Parameter query: The validated filters, page, and sort.
  /// - Returns: A GET endpoint with no body.
  public static func foodList(_ query: FoodListQuery) -> Self {
    builtIn(path: "/foods/list" + self.query(query.queryItems))
  }
}
