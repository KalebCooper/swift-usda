extension FoodRequest where Response == [Food] {
  /// Several foods in the full format, each in the shape its data type defines.
  ///
  /// The request sends ``Endpoint/foods(_:nutrients:)``. Unknown identifiers are omitted from the
  /// result, which is in the order the service returns it.
  ///
  /// ```swift
  /// let request: FoodRequest<[Food]> = .foods(try FoodIDs([167_782, 2_768_188]))
  /// ```
  ///
  /// - Parameters:
  ///   - ids: The foods' FoodData Central identifiers.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: A single-endpoint request.
  public static func foods(_ ids: FoodIDs, nutrients: NutrientNumbers? = nil) -> Self {
    Self(endpoint: .foods(ids, nutrients: nutrients))
  }
}

extension FoodRequest where Response == [AbridgedFood] {
  /// Several foods in the abridged format.
  ///
  /// The request sends ``Endpoint/abridgedFoods(_:nutrients:)``. Unknown identifiers are omitted
  /// from the result, which is in the order the service returns it.
  ///
  /// ```swift
  /// let request: FoodRequest<[AbridgedFood]> = .abridgedFoods(try FoodIDs([167_782, 2_768_188]))
  /// ```
  ///
  /// - Parameters:
  ///   - ids: The foods' FoodData Central identifiers.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: A single-endpoint request.
  public static func abridgedFoods(_ ids: FoodIDs, nutrients: NutrientNumbers? = nil) -> Self {
    Self(endpoint: .abridgedFoods(ids, nutrients: nutrients))
  }
}
