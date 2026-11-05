import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite("FoodData Central food list page", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodDataCentralClientFoodListTests {
  @Test("A list request fetches one authenticated page and pairs it with its query")
  func aListRequestFetchesOneAuthenticatedPageAndPairsItWithItsQuery() async throws {
    let body = try Fixture.listFoundationPage2.data()
    let transport = MockTransport(results: [.success(.ok(json: body))])
    let client = try makeClient(transport)
    let query = try FoodListQuery(dataTypes: [.foundation], pageNumber: 2, pageSize: 2)
    let page = try await client.value(for: .foodList(query))
    #expect(page.pageNumber == 2)
    #expect(page.pageSize == 2)
    #expect(page.foods.map(\.fdcID) == [2_257_045, 1_999_631])
    let field = try #require(HTTPField.Name("X-Api-Key"))
    #expect(transport.requests.count == 1)
    let call = try #require(transport.requests.first)
    #expect(call.request.method == .get)
    #expect(call.request.authority == "api.nal.usda.gov")
    #expect(call.request.path == "/fdc/v1/foods/list?dataType=Foundation&pageNumber=2&pageSize=2")
    #expect(call.request.headerFields[field] == "private-test-key")
    #expect(call.body == .none)
  }

  @Test("A list request and its endpoint return the same foods")
  func aListRequestAndItsEndpointReturnTheSameFoods() async throws {
    let body = try Fixture.listFoundationPage1.data()
    let transport = MockTransport(results: Array(repeating: .success(.ok(json: body)), count: 2))
    let client = try makeClient(transport)
    let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 2)
    let page = try await client.value(for: .foodList(query))
    let foods = try await client.send(.foodList(query))
    #expect(page.foods == foods)
    #expect(transport.requests.count == 2)
    for call in transport.requests {
      #expect(call.request.path == "/fdc/v1/foods/list?dataType=Foundation&pageNumber=1&pageSize=2")
    }
  }

  @Test("A generic caller executes a list request through the generic overload")
  func aGenericCallerExecutesAListRequestThroughTheGenericOverload() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.listFoundationPage2.data()))
    ])
    let client = try makeClient(transport)
    let query = try FoodListQuery(dataTypes: [.foundation], pageNumber: 2, pageSize: 2)
    let page = try await Self.run(.foodList(query), on: client)
    #expect(page.pageNumber == 2)
    #expect(page.pageSize == 2)
    #expect(page.foods.map(\.fdcID) == [2_257_045, 1_999_631])
    #expect(
      transport.requests.compactMap(\.request.path)
        == ["/fdc/v1/foods/list?dataType=Foundation&pageNumber=2&pageSize=2"])
  }

  @Test("A cancelled list request sends nothing")
  func aCancelledListRequestSendsNothing() async throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    let query = try FoodListQuery()
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        do throws(FoodDataCentralError) {
          _ = try await client.value(for: .foodList(query))
          Issue.record("Cancellation must fail the list request.")
        } catch {
          guard case .transport(.cancelled) = error else {
            Issue.record("Expected typed cancellation, received \(error).")
            return
          }
        }
      }
    }
    #expect(transport.requests.isEmpty)
  }

  // Generic over the response, so `value(for:)` resolves to the generic overload.
  private static func run<Value: Decodable & SendableMetatype>(
    _ request: FoodRequest<Value>, on client: FoodDataCentralClient
  ) async throws(FoodDataCentralError) -> Value {
    try await client.value(for: request)
  }

  private func makeClient(
    _ transport: MockTransport
  ) throws(FoodDataCentralError) -> FoodDataCentralClient {
    FoodDataCentralClient(
      configuration: try FoodDataCentralConfiguration(apiKey: "private-test-key"),
      transport: transport)
  }
}
