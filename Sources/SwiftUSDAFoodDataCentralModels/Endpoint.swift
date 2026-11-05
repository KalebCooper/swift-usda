#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// One request to the FoodData Central API, described as plain values, and the type its response
/// decodes as.
///
/// An endpoint names a path relative to `https://api.nal.usda.gov/fdc/v1` for a `GET` request with
/// no body. It sends nothing itself: `SwiftUSDAFoodDataCentral` sends it, or a networking stack of
/// your own does, by requesting ``path`` with your data.gov API key in the `X-Api-Key` header, then
/// decoding the response body as `Response`.
/// The key never belongs in this value, and both initializers reject an `api_key` query parameter.
///
/// ```swift
/// let endpoint = Endpoint<Food>.food(2_346_404)
/// print(endpoint.path)  // "/food/2346404?format=full"
/// ```
public struct Endpoint<Response>: Hashable, Sendable {
  /// The validated percent-encoded path and optional query, relative to
  /// `https://api.nal.usda.gov/fdc/v1`, starting with one slash.
  ///
  /// The exact spelling is retained and cannot be changed after initialization.
  public let path: String

  /// Creates an endpoint from an absolute HTTPS FoodData Central API link.
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

  /// Creates a GET endpoint from an encoded relative API path and optional query.
  ///
  /// Returns `nil` for an absolute or authority path, an empty resource path such as `/`, a
  /// fragment, raw whitespace or other bytes outside printable ASCII, a backslash, a dot segment in
  /// any spelling, or an `api_key` query parameter in any letter case or encoding. Accepted text is retained exactly, without normalization.
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
