/// A FoodData Central operation described as a value, and the type its result has.
///
/// A request performs no I/O when it is created or stored. `SwiftUSDAFoodDataCentral` executes it
/// with `value(for:)`; a networking stack of your own interprets its public ``resolution``. Named
/// factories such as ``food(_:nutrients:)`` infer the response type from context, and
/// ``init(endpoint:)`` wraps any single endpoint, including one with a consumer-defined response.
///
/// ```swift
/// let request: FoodRequest<Food> = .food(2_346_404)
/// if case .endpoint(let endpoint) = request.resolution {
///   print(endpoint.path)  // "/food/2346404?format=full"
/// }
/// ```
public struct FoodRequest<Response>: Hashable, Sendable {
  /// How a request is carried out.
  public enum Resolution: Hashable, Sendable {
    /// Send one endpoint and decode its response.
    case endpoint(Endpoint<Response>)
    /// Send ``Endpoint/foodList(_:)`` for the query and wrap the returned foods in a
    /// ``FoodListPage``; ``FoodListQuery/next(after:)`` describes each following page.
    ///
    /// Only ``FoodRequest/foodList(_:)`` creates this resolution, so it appears only when
    /// `Response` is ``FoodListPage``.
    case foodList(FoodListQuery)
  }

  /// How this request is carried out.
  public let resolution: Resolution

  /// Creates a request that sends one endpoint.
  ///
  /// A real `/foods/list` response is a bare array, which cannot decode as ``FoodListPage``; list
  /// foods with `Endpoint<[AbridgedFood]>` or ``FoodRequest/foodList(_:)`` instead.
  /// - Parameter endpoint: The endpoint to send.
  public init(endpoint: Endpoint<Response>) {
    self.resolution = .endpoint(endpoint)
  }

  init(resolution: Resolution) {
    self.resolution = resolution
  }
}

extension FoodRequest where Response == Food {
  /// One food in the full format, in the shape its data type defines.
  ///
  /// The request sends ``Endpoint/food(_:nutrients:)``.
  ///
  /// ```swift
  /// let request: FoodRequest<Food> = .food(2_346_404)
  /// ```
  ///
  /// - Parameters:
  ///   - id: The food's FoodData Central identifier.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: A single-endpoint request.
  public static func food(_ id: FoodID, nutrients: NutrientNumbers? = nil) -> Self {
    Self(endpoint: .food(id, nutrients: nutrients))
  }
}

extension FoodRequest where Response == AbridgedFood {
  /// One food in the abridged format.
  ///
  /// The request sends ``Endpoint/abridgedFood(_:nutrients:)``.
  ///
  /// ```swift
  /// let request: FoodRequest<AbridgedFood> = .abridgedFood(2_346_404)
  /// ```
  ///
  /// - Parameters:
  ///   - id: The food's FoodData Central identifier.
  ///   - nutrients: The nutrients to return, or `nil` for all of them.
  /// - Returns: A single-endpoint request.
  public static func abridgedFood(_ id: FoodID, nutrients: NutrientNumbers? = nil) -> Self {
    Self(endpoint: .abridgedFood(id, nutrients: nutrients))
  }
}
