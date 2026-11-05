/// A value rejected before any request is described, because it breaks a documented FoodData
/// Central limit.
///
/// ```swift
/// do {
///   _ = try NutrientNumbers([])
/// } catch {
///   print(error)  // nutrientNumberCount(0)
/// }
/// ```
public enum FoodDataCentralValidationError: Error, Hashable, Sendable {
  /// A food identifier appeared more than once; the associated value is the first repeat.
  case duplicateFoodID(FoodID)
  /// A nutrient number appeared more than once; the associated value is the first repeat.
  case duplicateNutrientNumber(NutrientNumber)
  /// A search query was empty or held only whitespace.
  case emptySearchQuery
  /// A food identifier list was empty or longer than ``FoodIDs/maximumCount``; the associated
  /// value is the count given.
  case foodIDCount(Int)
  /// A nutrient list was empty or longer than ``NutrientNumbers/maximumCount``; the associated
  /// value is the count given.
  case nutrientNumberCount(Int)
  /// A page number was less than 1, the first page; the associated value is the number given.
  case pageNumber(Int)
  /// A page size was outside 1 to ``FoodListQuery/maximumPageSize`` or
  /// ``FoodSearchQuery/maximumPageSize``; the associated value is the size given.
  case pageSize(Int)
  /// A year, month, and day named no Gregorian date with a four-digit year.
  case publicationDate(year: Int, month: Int, day: Int)
  /// A search's start date fell after its end date.
  case publicationDateRange(start: FoodPublicationDate, end: FoodPublicationDate)
  /// A trade channel filter held more than ``FoodSearchQuery/maximumTradeChannelCount`` channels;
  /// the associated value is the count given.
  case tradeChannelCount(Int)
}
