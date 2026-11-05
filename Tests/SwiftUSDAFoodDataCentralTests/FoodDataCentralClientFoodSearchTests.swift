import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite("FoodData Central food search page", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodDataCentralClientFoodSearchTests {
  @Test("A search request posts its JSON body with the key header")
  func aSearchRequestPostsItsJSONBodyWithTheKeyHeader() async throws {
    let body = Data(
      #"{"totalHits":1,"currentPage":1,"totalPages":1,"foods":[{"fdcId":2346404,"description":"Apples, raw"}]}"#
        .utf8)
    let transport = MockTransport(results: [.success(.ok(json: body))])
    let client = FoodDataCentralClient(
      configuration: try FoodDataCentralConfiguration(apiKey: "private-test-key"),
      transport: transport)
    let query = try FoodSearchQuery("apple", dataTypes: [.foundation], pageSize: 25)
    let page = try await client.value(for: .foodSearch(query))
    #expect(page.foods.map(\.fdcID) == [2_346_404])
    let field = try #require(HTTPField.Name("X-Api-Key"))
    #expect(transport.requests.count == 1)
    let call = try #require(transport.requests.first)
    #expect(call.request.method == .post)
    #expect(call.request.authority == "api.nal.usda.gov")
    #expect(call.request.path == "/fdc/v1/foods/search")
    #expect(call.request.headerFields[.contentType] == "application/json")
    #expect(call.request.headerFields[field] == "private-test-key")
    #expect(
      call.body
        == .bytes(
          Data(
            #"{"dataType":["Foundation"],"pageNumber":1,"pageSize":25,"query":"apple"}"#.utf8)))
  }
}
