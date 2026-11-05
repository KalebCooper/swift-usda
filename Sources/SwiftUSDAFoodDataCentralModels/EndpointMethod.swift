/// The HTTP method an ``Endpoint`` uses.
///
/// Every FoodData Central endpoint this package describes is a `GET` request except a food search,
/// which is a `POST` with a JSON body so it can carry the filters only the body accepts.
///
/// ```swift
/// let endpoint = Endpoint.foodSearch(try FoodSearchQuery("cheddar cheese"))
/// print(endpoint.method)  // post
/// ```
public enum EndpointMethod: String, Hashable, Sendable {
  /// `GET`, with no request body.
  case get = "GET"
  /// `POST`, with the endpoint's JSON body.
  case post = "POST"
}
