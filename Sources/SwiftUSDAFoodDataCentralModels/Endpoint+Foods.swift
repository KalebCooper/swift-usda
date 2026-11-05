extension Endpoint where Response == [Food] {
  /// Several foods in the full format, `GET /foods?fdcIds=...&format=full`.
  ///
  /// Each food arrives in the shape its data type defines. The FoodData Central specification
  /// says the service omits identifiers it does not know, so the array can be shorter than `ids`,
  /// and empty when none are known. The array is in the order the service returns it; FoodData
  /// Central does not document that order. Per the specification, `nutrients` restricts the
  /// nutrients returned for each food. No `/foods` response has been recorded, so this endpoint
  /// and the `nutrients` filter follow the specification and are unverified.
  ///
  /// ```swift
  /// Endpoint.foods(try FoodIDs([167_782, 2_768_188])).path
  /// // "/foods?fdcIds=167782,2768188&format=full"
  /// ```
  ///
  /// - Parameters:
  ///   - ids: The foods' FoodData Central identifiers, sent comma-separated in the order given.
  ///   - nutrients: The nutrients to return, sent in the order given, or `nil` for all of them.
  /// - Returns: A GET endpoint with no body.
  public static func foods(_ ids: FoodIDs, nutrients: NutrientNumbers? = nil) -> Self {
    multipleLookup(ids, format: "full", nutrients: nutrients)
  }
}

extension Endpoint where Response == [AbridgedFood] {
  /// Several foods in the abridged format, `GET /foods?fdcIds=...&format=abridged`.
  ///
  /// The abridged format has one shape for every data type. Unknown identifiers are omitted and
  /// the order is the service's, as for ``Endpoint/foods(_:nutrients:)``, and nutrients are
  /// filtered the same way. Like that endpoint, it follows the specification and is unrecorded.
  ///
  /// ```swift
  /// Endpoint.abridgedFoods(try FoodIDs([167_782, 2_768_188])).path
  /// // "/foods?fdcIds=167782,2768188&format=abridged"
  /// ```
  ///
  /// - Parameters:
  ///   - ids: The foods' FoodData Central identifiers, sent comma-separated in the order given.
  ///   - nutrients: The nutrients to return, sent in the order given, or `nil` for all of them.
  /// - Returns: A GET endpoint with no body.
  public static func abridgedFoods(_ ids: FoodIDs, nutrients: NutrientNumbers? = nil) -> Self {
    multipleLookup(ids, format: "abridged", nutrients: nutrients)
  }
}

extension Endpoint {
  fileprivate static func multipleLookup(
    _ ids: FoodIDs, format: String, nutrients: NutrientNumbers?
  ) -> Self {
    var items: [(name: String, value: String)] = [("fdcIds", ids.queryValue), ("format", format)]
    if let nutrients { items.append(("nutrients", nutrients.queryValue)) }
    return builtIn(path: "/foods" + query(items))
  }
}
