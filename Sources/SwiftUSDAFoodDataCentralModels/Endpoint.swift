#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One request to the FoodData Central API, described as plain values, and the type its response
/// decodes as.
///
/// An endpoint names a path relative to `https://api.nal.usda.gov/fdc/v1`, its ``method``, and, for a
/// search, a JSON ``body``. It sends nothing itself: `SwiftUSDAFoodDataCentral` sends it, or a
/// networking stack of your own does, by requesting ``path`` with ``method`` and ``body`` (as
/// `application/json`) and your data.gov API key in the `X-Api-Key` header, then decoding the
/// response body with ``decode(_:)``.
/// The key never belongs in this value, and both initializers reject an `api_key` query parameter.
///
/// Equality and hashing cover the method, path, body, and how the response decodes. An endpoint
/// from ``foods(_:nutrients:)`` or ``abridgedFoods(_:nutrients:)`` therefore differs from one
/// created with ``init(path:)`` for the same path, because only the factories read an empty JSON
/// object as no foods.
///
/// ```swift
/// let endpoint = Endpoint<Food>.food(2_346_404)
/// print(endpoint.path)  // "/food/2346404?format=full"
/// ```
public struct Endpoint<Response>: Hashable, Sendable {
  /// The UTF-8 JSON request body, or `nil` when the request sends none.
  ///
  /// Only ``foodSearch(_:)`` produces a body; every endpoint created from a path or a link sends
  /// none. The bytes are fixed when the endpoint is created and take part in equality and hashing.
  public let body: Data?

  // Whether a body that is exactly an empty JSON object decodes as an empty array. Only the
  // multiple-food factories set it, because `/foods` answers `{}` when it knows none of the
  // identifiers.
  let decodesEmptyObjectAsEmptyArray: Bool

  /// The HTTP method the request uses.
  ///
  /// Endpoints created from a path or a link are ``EndpointMethod/get``. Only ``foodSearch(_:)``
  /// produces ``EndpointMethod/post``.
  public let method: EndpointMethod

  /// The validated percent-encoded path and optional query, relative to
  /// `https://api.nal.usda.gov/fdc/v1`, starting with one slash.
  ///
  /// The exact spelling is retained and cannot be changed after initialization.
  public let path: String

  /// Creates a GET endpoint with no body from an absolute HTTPS FoodData Central API link.
  ///
  /// Only `api.nal.usda.gov`, with no port or port 443, and paths below `/fdc/v1/` are accepted.
  /// Returns `nil` for another scheme or origin, credentials, a fragment, an `api_key` query
  /// parameter, a link naming no resource below the base, or a path ``init(path:)`` rejects.
  /// Encoded paths and queries are retained.
  ///
  /// ```swift
  /// let link = URL(string: "https://api.nal.usda.gov/fdc/v1/food/2346404")!
  /// let endpoint = Endpoint<Food>(link: link)
  /// print(endpoint?.path)  // Optional("/food/2346404")
  /// ```
  ///
  /// - Parameter link: An absolute URL to interpret with a consumer-defined response type.
  public init?(link: URL) {
    guard let components = URLComponents(url: link, resolvingAgainstBaseURL: false),
      components.scheme?.lowercased() == "https",
      components.host?.lowercased() == "api.nal.usda.gov",
      components.port == nil || components.port == 443,
      components.user == nil, components.password == nil,
      components.fragment == nil,
      components.percentEncodedPath.hasPrefix("/fdc/v1/")
    else { return nil }
    let query = components.percentEncodedQuery.map { "?" + $0 } ?? ""
    self.init(path: String(components.percentEncodedPath.dropFirst("/fdc/v1".count)) + query)
  }

  /// Creates a GET endpoint with no body from an encoded relative API path and optional query.
  ///
  /// Returns `nil` for an absolute or authority path, an empty resource path such as `/`, a
  /// fragment, raw whitespace or other bytes outside printable ASCII, a backslash, a dot segment in
  /// any spelling, or an `api_key` query parameter in any letter case or encoding. Accepted text
  /// is retained exactly, without normalization.
  ///
  /// ```swift
  /// let endpoint = Endpoint<Food>(path: "/food/2346404?format=full")
  /// ```
  ///
  /// - Parameter path: A path relative to `https://api.nal.usda.gov/fdc/v1`, starting with `/`.
  public init?(path: String) {
    guard path.hasPrefix("/"), !path.hasPrefix("//"),
      path.utf8.allSatisfy({ (33...126).contains($0) }),
      let components = URLComponents(string: path),
      components.scheme == nil, components.host == nil,
      components.fragment == nil,
      components.percentEncodedPath == String(path.split(separator: "?", maxSplits: 1)[0]),
      !components.path.contains("\\"),
      !components.path.hasPrefix("//"),
      components.path != "/",
      !components.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }),
      !(components.queryItems ?? []).contains(where: { $0.name.lowercased() == "api_key" })
    else { return nil }
    self.body = nil
    self.decodesEmptyObjectAsEmptyArray = false
    self.method = .get
    self.path = path
  }

  private init(
    body: Data?, decodesEmptyObjectAsEmptyArray: Bool, method: EndpointMethod, path: String
  ) {
    self.body = body
    self.decodesEmptyObjectAsEmptyArray = decodesEmptyObjectAsEmptyArray
    self.method = method
    self.path = path
  }

  // Only fixed routes with validated values and encoded queries use this construction. Validation
  // still runs, so there is no alternate unchecked endpoint representation.
  static func builtIn(path: String) -> Self {
    guard let endpoint = Self(path: path) else {
      preconditionFailure("Fixed routes with validated values and encoded queries are valid paths.")
    }
    return endpoint
  }

  // A fixed route sent as POST with a JSON body. The route is validated like any other path.
  static func builtIn(path: String, postingJSON body: Data) -> Self {
    Self(
      body: body, decodesEmptyObjectAsEmptyArray: false, method: .post,
      path: builtIn(path: path).path)
  }

  // A fixed GET route whose response is an array the service sends as `{}` when it is empty.
  static func builtIn(emptyObjectAsEmptyArrayPath path: String) -> Self {
    Self(
      body: nil, decodesEmptyObjectAsEmptyArray: true, method: .get,
      path: builtIn(path: path).path)
  }

  // Joins name-value pairs in the given order, percent-encoding every byte outside the unreserved
  // set except the comma that separates list values, so a value cannot add a parameter.
  static func query(_ items: [(name: String, value: String)]) -> String {
    guard !items.isEmpty else { return "" }
    return "?" + items.map { encoded($0.name) + "=" + encoded($0.value) }.joined(separator: "&")
  }

  private static func encoded(_ value: String) -> String {
    value.utf8.map { byte -> String in
      switch byte {
      case 44, 45, 46, 48...57, 65...90, 95, 97...122, 126:
        String(UnicodeScalar(byte))
      default:
        "%" + (byte < 16 ? "0" : "") + String(byte, radix: 16, uppercase: true)
      }
    }.joined()
  }
}

extension Endpoint where Response: Decodable {
  /// Decodes a successful response body as this endpoint's response type.
  ///
  /// The body is read as JSON. For an endpoint from ``foods(_:nutrients:)`` or
  /// ``abridgedFoods(_:nutrients:)``, a body that is exactly an empty JSON object, with any
  /// whitespace around or inside the braces, decodes as an empty array: FoodData Central answers
  /// `/foods` with `{}` rather than `[]` when it knows none of the identifiers. Any other object,
  /// and any body for every other endpoint, decodes normally, so a non-empty object still fails.
  /// Use this method when you send endpoints with your own networking stack, so your decoding
  /// matches `SwiftUSDAFoodDataCentral`'s.
  ///
  /// ```swift
  /// let endpoint = Endpoint.foods(try FoodIDs([999_999_998, 999_999_999]))
  /// let (body, _) = try await session.data(for: urlRequest(for: endpoint))
  /// let foods = try endpoint.decode(body)  // [] when the service sends {}
  /// ```
  ///
  /// - Parameter body: The response body of a successful (`2xx`) response.
  /// - Returns: The decoded response.
  /// - Throws: `DecodingError` when the body is not JSON or does not have the response's shape. An
  ///   error of another type thrown while decoding is reported as `DecodingError.dataCorrupted`
  ///   with that error as its underlying error.
  public func decode(_ body: Data) throws(DecodingError) -> Response {
    // Every endpoint that sets the flag has an array response, so `[]` decodes as that response.
    let source = decodesEmptyObjectAsEmptyArray && Self.isEmptyObject(body) ? Data("[]".utf8) : body
    do {
      return try JSONDecoder().decode(Response.self, from: source)
    } catch let error as DecodingError {
      throw error
    } catch {
      throw .dataCorrupted(
        DecodingError.Context(
          codingPath: [], debugDescription: "The response body could not be decoded.",
          underlyingError: error))
    }
  }

  // Whether the bytes are `{` and `}` with only JSON whitespace around and between them.
  private static func isEmptyObject(_ body: Data) -> Bool {
    let significant = body.filter { ![0x09, 0x0A, 0x0D, 0x20].contains($0) }
    return significant.elementsEqual([0x7B, 0x7D])
  }
}
