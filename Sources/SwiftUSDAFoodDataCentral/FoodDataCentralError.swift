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
}
