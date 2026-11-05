extension Endpoint where Response == Food {
  /// One food in the full format, `GET /food/{fdcId}?format=full`.
  ///
  /// FoodData Central documents a `404` status for an identifier it does not know and a `400`
  /// status for invalid input; the bodies of those responses have not been recorded. Per the
  /// FoodData Central specification, `nutrients` restricts the nutrients returned. No response
  /// with a `nutrients` filter has been recorded, so what comes back for a food with none of the
  /// requested nutrients is unverified.
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
  /// The abridged format has one shape for every data type. FoodData Central documents `404` for
  /// an identifier it does not know and `400` for invalid input; the bodies of those responses
  /// have not been recorded. The `nutrients` filter follows the specification, as for
  /// ``Endpoint/food(_:nutrients:)``, and is unrecorded.
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
