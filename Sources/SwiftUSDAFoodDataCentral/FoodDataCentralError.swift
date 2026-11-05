#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
// The public client and error name Transport and TransportError, so consumers need their members
// available without separately declaring an HTTPCore dependency.
@_exported import HTTPCore
import SwiftUSDAFoodDataCentralModels

/// The typed failure of a FoodData Central client operation or credential configuration.
///
/// ```swift
/// do {
///   let food = try await client.food(2_346_404)
/// } catch {
///   switch error {
///   case .gateway(let response, _): print(response.error.code)
///   case .invalidAPIKey: print("The key cannot be sent.")
///   case .pagination(let failure): print(failure)
///   case .transport(let failure): print(failure)
///   }
/// }
/// ```
public enum FoodDataCentralError: Error {
  /// The api.data.gov gateway returned its error body.
  ///
  /// Covers credential and rate-limit failures such as `API_KEY_MISSING`, `API_KEY_INVALID`, and
  /// `OVER_RATE_LIMIT`, and any code the gateway adds later. The HTTP failure retains the original
  /// body, status, and headers, including rate-limit information. Neither the message nor those
  /// fields should be logged without review.
  case gateway(DataGovErrorResponse, response: TransportError)

  /// The API key is empty or contains characters unsuitable for an HTTP header.
  ///
  /// The rejected credential is deliberately not attached to the error.
  case invalidAPIKey

  /// A food list or food search page sequence cannot safely continue.
  ///
  /// Only ``FoodListPageSequence``, ``FoodListItemSequence``, ``FoodSearchPageSequence``, and
  /// ``FoodSearchItemSequence`` report this case, before yielding the page that caused it. It
  /// carries `FoodPaginationError.resultWindowExceeded` when the service refuses a page past its
  /// result window, or the error `FoodListQuery.next(after:)` or `FoodSearchQuery.next(after:)`
  /// throws for a page it cannot continue from. A single page fetched with the client's
  /// `value(for:)` or `send(_:)` reports a refused page as ``transport(_:)`` instead.
  case pagination(FoodPaginationError)

  /// A connection, cancellation, decoding, or HTTP status failure without a gateway error body.
  ///
  /// An unknown food identifier (`404`) and a rejected request (`400`) arrive here as
  /// `TransportError.httpStatus` with the original body. Redirects are returned here as HTTP
  /// failures and are never followed with the API key.
  case transport(TransportError)

  init(_ failure: TransportError) {
    if case .httpStatus(let body, _, _) = failure,
      let response = try? JSONDecoder().decode(DataGovErrorResponse.self, from: body)
    {
      self = .gateway(response, response: failure)
    } else {
      self = .transport(failure)
    }
  }

  // Maps a page sequence's failure. The service answers a page past its result window with `400`
  // and exactly this plain-text body; any other `400` stays a transport failure.
  static func paging(_ failure: TransportError) -> Self {
    if case .httpStatus(let body, 400, _) = failure, body == resultWindowBody {
      return .pagination(.resultWindowExceeded)
    }
    return Self(failure)
  }

  private static let resultWindowBody = Data(
    "Bad Request: pageSize * pageNumber exceeded upper search results limit.".utf8)
}
