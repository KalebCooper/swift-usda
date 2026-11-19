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

  @Test("A recorded full response decodes each food by data type, omitting the unknown one")
  func aRecordedFullResponseDecodesEachFoodByDataTypeOmittingTheUnknownOne() throws {
    let endpoint = Endpoint.foods(
      try FoodIDs([2_617_100, 2_768_188, 167_782, 2_706_337, 999_999_999]))
    let foods = try endpoint.decode(try Fixture.foodsMixedInvalid.data())
    #expect(
      foods.map(\.kindAndID) == [
        "branded 2617100", "foundation 2768188", "srLegacy 167782", "survey 2706337",
      ])
  }

  @Test("A recorded abridged response decodes in the order received, not the order requested")
  func aRecordedAbridgedResponseDecodesInTheOrderReceivedNotTheOrderRequested() throws {
    let endpoint = Endpoint.abridgedFoods(try FoodIDs([2_617_100, 2_768_188]))
    let foods = try endpoint.decode(try Fixture.foodsAbridged.data())
    #expect(foods.map(\.fdcID) == [2_768_188, 2_617_100])
    #expect(foods.map(\.dataType) == [.foundation, .branded])
    #expect(foods.first?.ndbNumber == "15266")
  }

  @Test("A recorded nutrient filter keeps only the requested legacy numbers in each food")
  func aRecordedNutrientFilterKeepsOnlyTheRequestedLegacyNumbersInEachFood() throws {
    let foods = try JSONDecoder().decode([Food].self, from: try Fixture.foodsNutrients.data())
    #expect(foods.map(\.kindAndID) == ["branded 2617100", "foundation 2768188"])
    for food in foods {
      #expect(Set(food.nutrientNumbers) == ["203", "204", "205"])
      #expect(food.nutrientNumbers.count == 3)
    }
  }

  @Test("A recorded lookup of only unknown identifiers decodes as no foods")
  func aRecordedLookupOfOnlyUnknownIdentifiersDecodesAsNoFoods() throws {
    let ids = try FoodIDs([999_999_998, 999_999_999])
    let body = try Fixture.foodsAllInvalid.data()
    #expect(body == Data("{}".utf8))
    #expect(try Endpoint.foods(ids).decode(body).isEmpty)
    #expect(try Endpoint.abridgedFoods(ids).decode(body).isEmpty)
  }

  @Test(
    "An empty object with whitespace decodes as no foods", arguments: [" {}\n", "{ }", "\t{\r\n}"])
  func anEmptyObjectWithWhitespaceDecodesAsNoFoods(_ body: String) throws {
    let ids = try FoodIDs([1])
    #expect(try Endpoint.foods(ids).decode(Data(body.utf8)).isEmpty)
    #expect(try Endpoint.abridgedFoods(ids).decode(Data(body.utf8)).isEmpty)
  }

  @Test("A non-empty object still fails to decode as foods")
  func aNonEmptyObjectStillFailsToDecodeAsFoods() throws {
    let ids = try FoodIDs([1])
    #expect(throws: DecodingError.self) {
      try Endpoint.foods(ids).decode(Data(#"{"a":1}"#.utf8))
    }
    #expect(throws: DecodingError.self) {
      try Endpoint.abridgedFoods(ids).decode(Data(#"{"a":1}"#.utf8))
    }
  }

  @Test("An endpoint created from a path decodes an empty object as a failure")
  func anEndpointCreatedFromAPathDecodesAnEmptyObjectAsAFailure() throws {
    let endpoint = try #require(Endpoint<[Food]>(path: "/foods?fdcIds=1&format=full"))
    #expect(endpoint != Endpoint.foods(try FoodIDs([1])))
    #expect(throws: DecodingError.self) {
      try endpoint.decode(Data("{}".utf8))
    }
  }

  @Test("An empty response decodes to no foods", arguments: ["[]", " [ ] "])
  func anEmptyResponseDecodesToNoFoods(_ body: String) throws {
    #expect(try JSONDecoder().decode([Food].self, from: Data(body.utf8)).isEmpty)
    #expect(try JSONDecoder().decode([AbridgedFood].self, from: Data(body.utf8)).isEmpty)
  }

  @Test("A contextual factory resolves to the full multiple-food endpoint")
  func aContextualFactoryResolvesToTheFullMultipleFoodEndpoint() throws {
    let ids = try FoodIDs([167_782, 2_768_188])
    let request: FoodRequest<[Food]> = .foods(ids)
    guard case .endpoint(let endpoint) = request.resolution else {
      Issue.record("Expected a single-endpoint resolution, got \(request.resolution).")
      return
    }
    #expect(endpoint == .foods(ids))
    #expect(endpoint.path == "/foods?fdcIds=167782,2768188&format=full")
  }

  @Test("An unannotated stored multiple-food request infers its response type")
  func anUnannotatedStoredMultipleFoodRequestInfersItsResponseType() throws {
    let ids = try FoodIDs([167_782])
    let request = FoodRequest.abridgedFoods(ids)
    let typed: FoodRequest<[AbridgedFood]> = request
    #expect(typed == FoodRequest(endpoint: .abridgedFoods(ids)))
    guard case .endpoint(let endpoint) = typed.resolution else {
      Issue.record("Expected a single-endpoint resolution, got \(typed.resolution).")
      return
    }
    #expect(endpoint.path == "/foods?fdcIds=167782&format=abridged")
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
    let names = try resolved.decode(try Fixture.foodsAbridged.data())
    #expect(
      names.map(\.description) == [
        "Alaska Pollock, raw", " ALL NATURAL GLUTEN FREE CHICKEN NUGGETS",
      ])
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

  // The legacy numbers of the food's nutrients, in the order received.
  fileprivate var nutrientNumbers: [String] {
    let nutrients: [FoodNutrient]? =
      switch self {
      case .branded(let food): food.foodNutrients
      case .foundation(let food): food.foodNutrients
      case .other: nil
      case .srLegacy(let food): food.foodNutrients
      case .survey(let food): food.foodNutrients
      }
    return (nutrients ?? []).compactMap { $0.nutrient?.number }
  }
}
