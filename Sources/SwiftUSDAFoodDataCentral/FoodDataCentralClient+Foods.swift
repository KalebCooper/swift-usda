import SwiftUSDAFoodDataCentralModels

extension FoodDataCentralClient {
  /// Looks up several foods in the abridged format.
  ///
  /// Sends `FoodRequest.abridgedFoods(_:nutrients:)` through `value(for:)`. The service omits
  /// identifiers it does not know, so the result can be shorter than `ids`, and it is empty when
  /// the service knows none of them (the service answers `{}`). The result is in the order the
  /// service returns it, which it does not document and which need not match `ids`.
  /// - Parameters:
  ///   - ids: The foods' FoodData Central identifiers.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: The known foods, each in the abridged shape shared by every data type.
  /// - Throws: ``FoodDataCentralError/gateway(_:response:)`` for gateway errors, or
  ///   ``FoodDataCentralError/transport(_:)`` for a rejected request (`400`), other HTTP,
  ///   decoding, connection, and cancellation failures.
  public func abridgedFoods(
    _ ids: FoodIDs, nutrients: NutrientNumbers? = nil
  ) async throws(FoodDataCentralError) -> [AbridgedFood] {
    try await value(for: .abridgedFoods(ids, nutrients: nutrients))
  }

  /// Looks up several foods in the full format, each in the shape its data type defines.
  ///
  /// Sends `FoodRequest.foods(_:nutrients:)` through `value(for:)`. The service omits identifiers
  /// it does not know, so the result can be shorter than `ids`, and it is empty when the service
  /// knows none of them (the service answers `{}`). The result is in the order the service returns
  /// it, which it does not document and which need not match `ids`.
  /// - Parameters:
  ///   - ids: The foods' FoodData Central identifiers.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: The known foods, each as the case of `Food` its data type selects.
  /// - Throws: ``FoodDataCentralError/gateway(_:response:)`` for gateway errors, or
  ///   ``FoodDataCentralError/transport(_:)`` for a rejected request (`400`), other HTTP,
  ///   decoding, connection, and cancellation failures.
  public func foods(
    _ ids: FoodIDs, nutrients: NutrientNumbers? = nil
  ) async throws(FoodDataCentralError) -> [Food] {
    try await value(for: .foods(ids, nutrients: nutrients))
  }
}
