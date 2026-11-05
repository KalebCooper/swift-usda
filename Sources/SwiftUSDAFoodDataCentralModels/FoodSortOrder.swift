/// The direction FoodData Central sorts foods in, the `sortOrder` parameter.
///
/// An order applies only together with a ``FoodSortField``, so it is part of ``FoodSort``.
///
/// ```swift
/// let sort = FoodSort(field: .publishedDate, order: .descending)
/// ```
public enum FoodSortOrder: String, Hashable, Sendable {
  /// Smallest or earliest first, `asc`.
  case ascending = "asc"
  /// Largest or latest first, `desc`.
  case descending = "desc"
}
