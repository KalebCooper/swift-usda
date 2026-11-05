import Foundation
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels

/// Text for the failures the demo shows, naming each typed error case.
enum ErrorDescription {
  static func text(for error: FoodDataCentralError) -> String {
    switch error {
    case .gateway(let body, _):
      "FoodDataCentralError.gateway \(body.error.code): \(body.error.message)"
    case .invalidAPIKey:
      "FoodDataCentralError.invalidAPIKey: the key is empty or cannot travel in an HTTP header. Nothing was sent."
    case .pagination(let failure):
      "FoodDataCentralError.pagination: \(failure)"
    case .transport(.httpStatus(let body, let code, _)):
      "FoodDataCentralError.transport: HTTP \(code). \(bodyText(body))"
    case .transport(let failure):
      "FoodDataCentralError.transport: \(failure)"
    }
  }

  static func text(for error: FoodDataCentralValidationError) -> String {
    switch error {
    case .emptySearchQuery:
      "Enter search terms. FoodDataCentralValidationError.emptySearchQuery; nothing was sent."
    default:
      "FoodDataCentralValidationError: \(error). Nothing was sent."
    }
  }

  /// The response body as UTF-8, cut to 200 characters. Header fields are never shown.
  private static func bodyText(_ body: Data) -> String {
    let text = String(decoding: body, as: UTF8.self)
    guard !text.isEmpty else { return "The response had no body." }
    return text.count > 200 ? "\(text.prefix(200))..." : text
  }
}
