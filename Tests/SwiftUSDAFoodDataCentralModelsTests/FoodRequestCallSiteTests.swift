import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

/// A response shape a consumer defines for a single endpoint of their own.
private struct FoodName: Decodable, Sendable {
  let description: String
}

extension FoodRequest where Response == AbridgedFood {
  /// A consumer-defined named factory built from the library's endpoint.
  fileprivate static func macronutrients(of id: FoodID) throws -> Self {
    Self(endpoint: .abridgedFood(id, nutrients: try NutrientNumbers([203, 204, 205])))
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodRequestCallSiteTests {
  @Test("A contextual factory resolves to the full food endpoint")
  func aContextualFactoryResolvesToTheFullFoodEndpoint() {
    let request: FoodRequest<Food> = .food(2_346_404)
    #expect(request.resolution == .endpoint(Endpoint(path: "/food/2346404?format=full")!))
  }

  @Test("An unannotated stored request infers its response type")
  func anUnannotatedStoredRequestInfersItsResponseType() {
    let request = FoodRequest.abridgedFood(167_782)
    let typed: FoodRequest<AbridgedFood> = request
    #expect(typed == FoodRequest(endpoint: .abridgedFood(167_782)))
  }

  @Test("A consumer-defined factory composes the library's endpoint")
  func aConsumerDefinedFactoryComposesTheLibrarysEndpoint() throws {
    let request = try FoodRequest.macronutrients(of: 167_782)
    guard case .endpoint(let endpoint) = request.resolution else { return }
    #expect(endpoint.path == "/food/167782?format=abridged&nutrients=203,204,205")
  }

  @Test("A consumer-defined response wraps a single endpoint")
  func aConsumerDefinedResponseWrapsASingleEndpoint() throws {
    let endpoint = try #require(Endpoint<FoodName>(path: "/food/167782?format=abridged"))
    let request = FoodRequest(endpoint: endpoint)
    guard case .endpoint(let resolved) = request.resolution else { return }
    #expect(resolved.path == "/food/167782?format=abridged")
    let name = try JSONDecoder().decode(
      FoodName.self, from: Data(#"{"description": "Abiyuch, raw"}"#.utf8))
    #expect(name.description == "Abiyuch, raw")
  }
}
