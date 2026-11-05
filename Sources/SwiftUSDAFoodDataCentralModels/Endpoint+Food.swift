extension Endpoint where Response == Food {
  /// One food in the full format, `GET /food/{fdcId}?format=full`.
  ///
  /// FoodData Central answers `404` for an identifier it does not know. With `nutrients`, only
  /// those nutrients are returned, and a food with none of them is returned with an empty nutrient
  /// list rather than an error.
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
  /// The abridged format has one shape for every data type. FoodData Central answers `404` for an
  /// identifier it does not know, and filters nutrients as ``Endpoint/food(_:nutrients:)`` does.
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
