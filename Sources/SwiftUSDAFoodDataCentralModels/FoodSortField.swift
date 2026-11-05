/// A field FoodData Central can sort foods by, as named on the wire in the `sortBy` parameter.
///
/// The type is open so a wire name can follow the service without a new type. The constants are
/// named for what they sort by. Only `fdcId` is confirmed by a recorded response; the other raw
/// values are the names the FoodData Central specification lists and have not been recorded. The
/// specification warns that the `dataType.keyword` and `lowercaseDescription.keyword` names will
/// change, but the service still rejects the announced replacement (`sortBy=description` returns
/// `400`), so the constants keep the listed names.
///
/// ```swift
/// let sort = FoodSort(field: .fdcID, order: .descending)
/// print(sort.field.rawValue)  // "fdcId"
/// ```
public struct FoodSortField: Hashable, RawRepresentable, Sendable {
  /// The food's data type, `dataType.keyword`.
  public static let dataType = FoodSortField(rawValue: "dataType.keyword")
  /// The food's description, ignoring letter case, `lowercaseDescription.keyword`.
  public static let description = FoodSortField(rawValue: "lowercaseDescription.keyword")
  /// The food's FoodData Central identifier, `fdcId`.
  public static let fdcID = FoodSortField(rawValue: "fdcId")
  /// The food's publication date, `publishedDate`.
  public static let publishedDate = FoodSortField(rawValue: "publishedDate")

  /// The field exactly as the `sortBy` parameter spells it.
  public let rawValue: String

  /// Creates a sort field from its wire spelling.
  ///
  /// The value is sent as given; the service rejects a name it does not know with `400`.
  /// - Parameter rawValue: The `sortBy` value, such as `fdcId`.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
