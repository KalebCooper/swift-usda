/// A calendar date in the form FoodData Central's search filters take, `YYYY-MM-DD`.
///
/// The value is a validated Gregorian date with a four-digit year, and it involves no time zone or
/// clock: it is the date as written. It is used for the search body's `startDate` and `endDate`
/// filters, which the FoodData Central specification (version 1.0.1) describes as filtering on
/// publication date. Those filters come from the specification and have not been verified against
/// the service.
///
/// ```swift
/// let date = try FoodPublicationDate(year: 2021, month: 1, day: 1)
/// print(date.description)  // "2021-01-01"
/// ```
public struct FoodPublicationDate: Comparable, CustomStringConvertible, Hashable, Sendable {
  /// The day of the month, from 1.
  public let day: Int
  /// The month, from 1 for January to 12.
  public let month: Int
  /// The year, from 1 to 9999.
  public let year: Int

  /// The date as `YYYY-MM-DD`, the form the search body sends.
  public var description: String {
    func padded(_ value: Int, to width: Int) -> String {
      let digits = String(value)
      return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
    return padded(year, to: 4) + "-" + padded(month, to: 2) + "-" + padded(day, to: 2)
  }

  /// Creates a validated date.
  /// - Parameters:
  ///   - year: The year, from 1 to 9999.
  ///   - month: The month, from 1 to 12.
  ///   - day: The day, from 1 to the last day of that month in the Gregorian calendar.
  /// - Throws: ``FoodDataCentralValidationError/publicationDate(year:month:day:)`` for a year,
  ///   month, or day that names no Gregorian date.
  public init(year: Int, month: Int, day: Int) throws(FoodDataCentralValidationError) {
    guard (1...9999).contains(year), (1...12).contains(month),
      (1...Self.days(inMonth: month, of: year)).contains(day)
    else { throw .publicationDate(year: year, month: month, day: day) }
    self.day = day
    self.month = month
    self.year = year
  }

  /// Returns whether one date is earlier than another.
  /// - Parameters:
  ///   - lhs: A date.
  ///   - rhs: Another date.
  /// - Returns: `true` when `lhs` falls before `rhs`.
  public static func < (lhs: Self, rhs: Self) -> Bool {
    (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
  }

  private static func days(inMonth month: Int, of year: Int) -> Int {
    switch month {
    case 2:
      let leap = year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
      return leap ? 29 : 28
    case 4, 6, 9, 11: return 30
    default: return 31
    }
  }
}
