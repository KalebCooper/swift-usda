#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPCore
import HTTPTypes
import SwiftUSDAFoodDataCentralModels

/// A Sendable client for the USDA FoodData Central API.
///
/// Use ``food(_:nutrients:)``, ``abridgedFood(_:nutrients:)``, ``foods(_:nutrients:)``, or
/// ``abridgedFoods(_:nutrients:)`` for an everyday lookup, `value(for:)` for a reusable request,
/// or ``send(_:)`` for a typed endpoint. List foods lazily with ``foodListPages(_:)`` and
/// ``foods(listing:)``, and search them lazily with ``foodSearchPages(_:)`` and
/// ``foods(matching:)``. For a list or search request, `pages(for:)` and `items(for:)` return the
/// matching page and food sequences. Every entry point sends the API key in the `X-Api-Key`
/// header, never in the URL, and reports the same typed errors. No retries or redirects are
/// performed automatically, and the client does not track the gateway's rate limit.
///
/// ```swift
/// let client = FoodDataCentralClient(
///   configuration: try FoodDataCentralConfiguration(apiKey: apiKey), transport: transport)
/// let food = try await client.food(2_346_404)
/// ```
public struct FoodDataCentralClient: Sendable {
  /// The explicit credential configuration used by this client.
  public let configuration: FoodDataCentralConfiguration

  let client: HTTPClient

  /// Creates a client using a supplied transport on any supported platform.
  /// - Parameters:
  ///   - configuration: Required API-key configuration.
  ///   - transport: The transport that sends each request.
  public init(configuration: FoodDataCentralConfiguration, transport: any Transport) {
    self.configuration = configuration
    self.client = HTTPClient(baseURL: Self.baseURL, redirectPolicy: .never, transport: transport)
  }

  /// Looks up one food in the abridged format.
  ///
  /// Sends `FoodRequest.abridgedFood(_:nutrients:)` through `value(for:)`.
  /// - Parameters:
  ///   - id: The food's FoodData Central identifier.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: The food in the abridged shape shared by every data type.
  /// - Throws: ``FoodDataCentralError/gateway(_:response:)`` for gateway errors, or
  ///   ``FoodDataCentralError/transport(_:)`` for an unknown identifier (`404` with an empty
  ///   body), a malformed identifier (`400`), other HTTP, decoding, connection, and cancellation
  ///   failures.
  public func abridgedFood(
    _ id: FoodID, nutrients: NutrientNumbers? = nil
  ) async throws(FoodDataCentralError) -> AbridgedFood {
    try await value(for: .abridgedFood(id, nutrients: nutrients))
  }

  /// Looks up one food in the full format, in the shape its data type defines.
  ///
  /// Sends `FoodRequest.food(_:nutrients:)` through `value(for:)`.
  /// - Parameters:
  ///   - id: The food's FoodData Central identifier.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: The food, as the case of `Food` its data type selects.
  /// - Throws: ``FoodDataCentralError/gateway(_:response:)`` for gateway errors, or
  ///   ``FoodDataCentralError/transport(_:)`` for an unknown identifier (`404` with an empty
  ///   body), a malformed identifier (`400`), other HTTP, decoding, connection, and cancellation
  ///   failures.
  public func food(
    _ id: FoodID, nutrients: NutrientNumbers? = nil
  ) async throws(FoodDataCentralError) -> Food {
    try await value(for: .food(id, nutrients: nutrients))
  }

  /// Sends one endpoint and decodes its body as the endpoint's response type.
  ///
  /// Cancellation is checked before sending. The API key is supplied only in a header. The body
  /// is decoded with the endpoint's `decode(_:)`, so a multiple-food lookup the service answers
  /// with an empty JSON object returns an empty array.
  /// - Parameter endpoint: A validated relative FoodData Central endpoint.
  /// - Returns: The decoded body.
  /// - Throws: ``FoodDataCentralError/gateway(_:response:)`` for gateway errors, or
  ///   ``FoodDataCentralError/transport(_:)`` for HTTP, decoding, connection, and cancellation
  ///   failures. A body that does not decode is `TransportError.decode(underlying:)`.
  public func send<Value: Decodable & SendableMetatype>(
    _ endpoint: Endpoint<Value>
  ) async throws(FoodDataCentralError) -> Value {
    guard !Task.isCancelled else { throw .transport(.cancelled) }
    let response: Response
    do throws(TransportError) {
      response = try await client.execute(request(for: endpoint))
    } catch {
      throw FoodDataCentralError(error)
    }
    return try await Self.decoded(response.body, for: endpoint)
  }

  // Parsing a large body, such as twenty full foods, is felt wherever the caller runs, so it
  // happens off the caller's executor.
  @concurrent
  private static func decoded<Value: Decodable & SendableMetatype>(
    _ body: Data, for endpoint: Endpoint<Value>
  ) async throws(FoodDataCentralError) -> sending Value {
    try decodedInline(body, for: endpoint)
  }

  // Returned plain rather than `sending`, so the typed rethrow and the `sending` result do not
  // share one body; every input is `Sendable`, which keeps the value disconnected for the caller.
  private static func decodedInline<Value: Decodable & SendableMetatype>(
    _ body: Data, for endpoint: Endpoint<Value>
  ) throws(FoodDataCentralError) -> Value {
    do throws(DecodingError) {
      return try endpoint.decode(body)
    } catch {
      throw .transport(.decode(underlying: error))
    }
  }

  /// Executes a reusable request without changing its response type.
  /// - Parameter request: The portable operation to execute.
  /// - Returns: The concrete response selected by its factory or consumer-defined endpoint.
  /// - Throws: The same ``FoodDataCentralError`` as ``send(_:)``, including cancellation.
  public func value<Value: Decodable & SendableMetatype>(
    for request: FoodRequest<Value>
  ) async throws(FoodDataCentralError) -> Value {
    switch request.resolution {
    case .endpoint(let endpoint):
      return try await send(endpoint)
    case .foodList(let query):
      guard let page = try await foodListPage(query) as? Value else {
        preconditionFailure("Only FoodRequest<FoodListPage> can hold a food list resolution.")
      }
      return page
    case .foodSearch(let query):
      guard let page = try await send(.foodSearch(query)) as? Value else {
        preconditionFailure("Only FoodRequest<FoodSearchResult> can hold a food search resolution.")
      }
      return page
    }
  }

  func request<Value>(for endpoint: Endpoint<Value>) -> Request {
    var headers = HTTPFields()
    headers[.accept] = "application/json"
    headers[Self.apiKeyField] = configuration.apiKey
    // The body is sent as the exact bytes the endpoint holds.
    let method: HTTPRequest.Method =
      switch endpoint.method {
      case .get: .get
      case .post: .post
      }
    return Request(
      body: endpoint.body.map { .bytes($0, contentType: "application/json") } ?? .none,
      headers: headers, method: method, path: endpoint.path)
  }

  private static let apiKeyField: HTTPField.Name = {
    guard let name = HTTPField.Name("X-Api-Key") else {
      preconditionFailure("X-Api-Key is a valid HTTP field name.")
    }
    return name
  }()

  private static let baseURL: URL = {
    guard let url = URL(string: "https://api.nal.usda.gov/fdc/v1") else {
      preconditionFailure("The FoodData Central API base is a valid HTTPS URL.")
    }
    return url
  }()
}
