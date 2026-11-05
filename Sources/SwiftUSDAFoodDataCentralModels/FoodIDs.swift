/// One to 20 distinct food identifiers, in the order given, for a multiple-food lookup.
///
/// FoodData Central accepts at most 20 identifiers on one `/foods` request. The identifiers are
/// sent in the order given; nothing is sorted, removed, or split across requests. The FoodData
/// Central specification says the service omits identifiers it does not know, so a response can
/// hold fewer foods than this list has identifiers.
///
/// ```swift
/// let ids = try FoodIDs([167_782, 2_768_188])
/// let endpoint = Endpoint<[Food]>.foods(ids)
/// print(endpoint.path)  // "/foods?fdcIds=167782,2768188&format=full"
/// ```
public struct FoodIDs: Hashable, Sendable {
  /// The largest number of food identifiers FoodData Central accepts on one request.
  public static let maximumCount = 20

  /// The food identifiers, in the order given.
  public let ids: [FoodID]

  /// Creates a validated list of food identifiers.
  /// - Parameter ids: One to ``maximumCount`` distinct food identifiers.
  /// - Throws: ``FoodDataCentralValidationError/foodIDCount(_:)`` for an empty list or one longer
  ///   than ``maximumCount``, and ``FoodDataCentralValidationError/duplicateFoodID(_:)`` naming
  ///   the first repeated identifier.
  public init(_ ids: [FoodID]) throws(FoodDataCentralValidationError) {
    guard (1...Self.maximumCount).contains(ids.count) else {
      throw .foodIDCount(ids.count)
    }
    var seen: Set<FoodID> = []
    for id in ids {
      if !seen.insert(id).inserted { throw .duplicateFoodID(id) }
    }
    self.ids = ids
  }

  // The comma-separated form the `fdcIds` query parameter takes.
  var queryValue: String {
    ids.map { String($0.rawValue) }.joined(separator: ",")
  }
}
