extension Endpoint where Response == [Food] {
  /// Several foods in the full format, `GET /foods?fdcIds=...&format=full`.
  ///
  /// Each food arrives in the shape its data type defines. The service omits identifiers it does
  /// not know, so the array can be shorter than `ids`. When it knows none of them it answers with
  /// an empty JSON object rather than an array; ``decode(_:)`` reads that body as an empty array.
  /// The array is in the order the service returns it, which FoodData Central does not document:
  /// one recorded response followed the order of `ids` and another did not. `nutrients` keeps
  /// only the nutrients whose legacy numbers it lists, in each food.
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
  /// The abridged format has one shape for every data type. Unknown identifiers are omitted, an
  /// empty JSON object decodes as no foods, the order is the service's, and nutrients are filtered,
  /// all as for ``Endpoint/foods(_:nutrients:)``.
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
    return builtIn(emptyObjectAsEmptyArrayPath: "/foods" + query(items))
  }
}
