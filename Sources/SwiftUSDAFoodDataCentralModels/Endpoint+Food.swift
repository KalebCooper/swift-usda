extension Endpoint where Response == Food {
  /// One food in the full format, `GET /food/{fdcId}?format=full`.
  ///
  /// The service answers an identifier it does not know with `404` and an empty body, and a
  /// malformed identifier with `400` and a small JSON body that is not a gateway error.
  /// `nutrients` keeps only the nutrients whose legacy numbers it lists, such as `203` for
  /// protein, not nutrient identifiers such as `1003`. What comes back for a food with none of the
  /// requested nutrients has not been recorded.
  ///
  /// ```swift
  /// Endpoint.food(2_346_404).path  // "/food/2346404?format=full"
  /// ```
  ///
  /// - Parameters:
  ///   - id: The food's FoodData Central identifier.
  ///   - nutrients: The nutrients to return, sent in the order given, or `nil` for all of them.
  /// - Returns: A GET endpoint with no body.
  public static func food(_ id: FoodID, nutrients: NutrientNumbers? = nil) -> Self {
    lookup(id, format: "full", nutrients: nutrients)
  }
}

extension Endpoint where Response == AbridgedFood {
  /// One food in the abridged format, `GET /food/{fdcId}?format=abridged`.
  ///
  /// The abridged format has one shape for every data type. Unknown and malformed identifiers fail
  /// as for ``Endpoint/food(_:nutrients:)``. The `nutrients` filter takes legacy nutrient numbers
  /// as there; it has been recorded only in the full format.
  ///
  /// ```swift
  /// Endpoint.abridgedFood(2_346_404).path  // "/food/2346404?format=abridged"
  /// ```
  ///
  /// - Parameters:
  ///   - id: The food's FoodData Central identifier.
  ///   - nutrients: The nutrients to return, sent in the order given, or `nil` for all of them.
  /// - Returns: A GET endpoint with no body.
  public static func abridgedFood(_ id: FoodID, nutrients: NutrientNumbers? = nil) -> Self {
    lookup(id, format: "abridged", nutrients: nutrients)
  }
}

extension Endpoint {
  fileprivate static func lookup(_ id: FoodID, format: String, nutrients: NutrientNumbers?)
    -> Self
  {
    var items: [(name: String, value: String)] = [("format", format)]
    if let nutrients { items.append(("nutrients", nutrients.queryValue)) }
    return builtIn(path: "/food/" + String(id.rawValue) + query(items))
  }
}
