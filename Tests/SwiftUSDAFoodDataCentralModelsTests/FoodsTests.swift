import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

/// A response shape a consumer defines for a multiple-food endpoint of their own.
private struct FoodName: Decodable, Sendable {
  let description: String
}

extension FoodRequest where Response == [AbridgedFood] {
  /// A consumer-defined named factory built from the library's endpoint.
  fileprivate static func macronutrients(of ids: FoodIDs) throws -> Self {
    Self(endpoint: .abridgedFoods(ids, nutrients: try NutrientNumbers([203, 204, 205])))
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodsTests {
  @Test("An empty identifier list is rejected with its count")
  func anEmptyIdentifierListIsRejectedWithItsCount() {
    #expect(throws: FoodDataCentralValidationError.foodIDCount(0)) {
      try FoodIDs([])
    }
  }

  @Test("Twenty-one identifiers are rejected with their count")
  func twentyOneIdentifiersAreRejectedWithTheirCount() {
    #expect(throws: FoodDataCentralValidationError.foodIDCount(21)) {
      try FoodIDs((1...21).map { FoodID($0) })
    }
  }

  @Test("A repeated identifier is rejected by name")
  func aRepeatedIdentifierIsRejectedByName() {
    #expect(throws: FoodDataCentralValidationError.duplicateFoodID(167_782)) {
      try FoodIDs([167_782, 2_768_188, 167_782])
    }
  }

  @Test("Twenty distinct identifiers are kept in the order given")
  func twentyDistinctIdentifiersAreKeptInTheOrderGiven() throws {
    let ids = (1...20).reversed().map { FoodID($0) }
    #expect(try FoodIDs(ids).ids == ids)
  }

  @Test("A full multiple-food lookup sends identifiers comma-separated with the full format")
  func aFullMultipleFoodLookupSendsIdentifiersCommaSeparatedWithTheFullFormat() throws {
    let endpoint = Endpoint<[Food]>.foods(try FoodIDs([2_768_188, 167_782]))
    #expect(endpoint.path == "/foods?fdcIds=2768188,167782&format=full")
  }

  @Test("An abridged multiple-food lookup sends its nutrients after the format")
  func anAbridgedMultipleFoodLookupSendsItsNutrientsAfterTheFormat() throws {
    let endpoint = Endpoint<[AbridgedFood]>.abridgedFoods(
      try FoodIDs([167_782, 2_768_188]), nutrients: try NutrientNumbers([205, 203, 204]))
    #expect(
      endpoint.path == "/foods?fdcIds=167782,2768188&format=abridged&nutrients=205,203,204")
  }

  @Test("A mixed full response decodes each food by data type in the order received")
  func aMixedFullResponseDecodesEachFoodByDataTypeInTheOrderReceived() throws {
    let body = try recordedArray(
      .foodSurveyFull, .foodBrandedFull, .foodSRLegacyFull, .foodFoundationFull)
    let foods = try JSONDecoder().decode([Food].self, from: body)
    #expect(
      foods.map(\.kindAndID) == [
        "survey 2706337", "branded 2617100", "srLegacy 167782", "foundation 2768188",
      ])
  }

  @Test("A response omitting an unknown identifier decodes only the known foods")
  func aResponseOmittingAnUnknownIdentifierDecodesOnlyTheKnownFoods() throws {
    // Requested 167782, 1, and 2768188; FoodData Central omits the unknown identifier 1.
    let body = try recordedArray(.foodSRLegacyFull, .foodFoundationFull)
    let foods = try JSONDecoder().decode([Food].self, from: body)
    #expect(foods.map(\.kindAndID) == ["srLegacy 167782", "foundation 2768188"])
  }

  @Test("A mixed abridged response decodes in the order received")
  func aMixedAbridgedResponseDecodesInTheOrderReceived() throws {
    let body = try recordedArray(.foodFoundationAbridged, .foodBrandedAbridged)
    let foods = try JSONDecoder().decode([AbridgedFood].self, from: body)
    #expect(foods.map(\.fdcID) == [2_768_188, 2_617_100])
    #expect(foods.map(\.dataType) == [.foundation, .branded])
    #expect(foods.first?.ndbNumber == "15266")
  }

  @Test("An empty response decodes to no foods", arguments: ["[]", " [ ] "])
  func anEmptyResponseDecodesToNoFoods(_ body: String) throws {
    #expect(try JSONDecoder().decode([Food].self, from: Data(body.utf8)).isEmpty)
    #expect(try JSONDecoder().decode([AbridgedFood].self, from: Data(body.utf8)).isEmpty)
  }

  @Test("A contextual factory resolves to the full multiple-food endpoint")
  func aContextualFactoryResolvesToTheFullMultipleFoodEndpoint() throws {
    let request: FoodRequest<[Food]> = .foods(try FoodIDs([167_782, 2_768_188]))
    #expect(
      request.resolution == .endpoint(Endpoint(path: "/foods?fdcIds=167782,2768188&format=full")!))
  }

  @Test("An unannotated stored multiple-food request infers its response type")
  func anUnannotatedStoredMultipleFoodRequestInfersItsResponseType() throws {
    let ids = try FoodIDs([167_782])
    let request = FoodRequest.abridgedFoods(ids)
    let typed: FoodRequest<[AbridgedFood]> = request
    #expect(typed == FoodRequest(endpoint: .abridgedFoods(ids)))
    #expect(
      typed.resolution == .endpoint(Endpoint(path: "/foods?fdcIds=167782&format=abridged")!))
  }

  @Test("A consumer-defined factory composes the library's multiple-food endpoint")
  func aConsumerDefinedFactoryComposesTheLibrarysMultipleFoodEndpoint() throws {
    let request = try FoodRequest.macronutrients(of: try FoodIDs([167_782, 2_768_188]))
    guard case .endpoint(let endpoint) = request.resolution else {
      Issue.record("Expected a single-endpoint resolution, got \(request.resolution).")
      return
    }
    #expect(
      endpoint.path == "/foods?fdcIds=167782,2768188&format=abridged&nutrients=203,204,205")
  }

  @Test("A consumer-defined response wraps a multiple-food endpoint")
  func aConsumerDefinedResponseWrapsAMultipleFoodEndpoint() throws {
    let endpoint = try #require(
      Endpoint<[FoodName]>(path: "/foods?fdcIds=167782,2768188&format=abridged"))
    let request = FoodRequest(endpoint: endpoint)
    guard case .endpoint(let resolved) = request.resolution else {
      Issue.record("Expected a single-endpoint resolution, got \(request.resolution).")
      return
    }
    #expect(resolved.path == "/foods?fdcIds=167782,2768188&format=abridged")
    let names = try JSONDecoder().decode(
      [FoodName].self, from: try recordedArray(.foodSRLegacyFull, .foodFoundationFull))
    #expect(names.map(\.description) == ["Abiyuch, raw", "Alaska Pollock, raw"])
  }

  // The `/foods` array wrapper is not yet recorded; each element is a recorded `/food/{fdcId}`
  // body, which the specification gives the same shape as a `/foods` element.
  private func recordedArray(_ fixtures: Fixture...) throws -> Data {
    var body = Data("[".utf8)
    for (index, fixture) in fixtures.enumerated() {
      if index > 0 { body.append(contentsOf: Data(",".utf8)) }
      body.append(try fixture.data())
    }
    body.append(contentsOf: Data("]".utf8))
    return body
  }
}

extension Food {
  // The case name and identifier, for comparing a decoded array with its expected order.
  fileprivate var kindAndID: String {
    switch self {
    case .branded(let food): "branded \(food.fdcID.rawValue)"
    case .foundation(let food): "foundation \(food.fdcID.rawValue)"
    case .other(let dataType, _): "other \(dataType.rawValue)"
    case .srLegacy(let food): "srLegacy \(food.fdcID.rawValue)"
    case .survey(let food): "survey \(food.fdcID.rawValue)"
    }
  }
}
