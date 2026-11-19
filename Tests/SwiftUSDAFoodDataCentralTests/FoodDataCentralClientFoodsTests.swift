import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite("FoodData Central multiple-food lookup", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodDataCentralClientFoodsTests {
  @Test("All full multiple-food entry points send equivalent authenticated requests")
  func allFullMultipleFoodEntryPointsSendEquivalentAuthenticatedRequests() async throws {
    let body = try Fixture.foodsMixedInvalid.data()
    let transport = MockTransport(results: Array(repeating: .success(.ok(json: body)), count: 3))
    let client = try makeClient(transport)
    let ids = try FoodIDs([2_617_100, 2_768_188, 167_782, 2_706_337, 999_999_999])
    let everyday = try await client.foods(ids)
    let reusable = try await client.value(for: .foods(ids))
    let endpoint = try await client.send(.foods(ids))
    #expect(everyday == reusable)
    #expect(reusable == endpoint)
    #expect(everyday.count == 4)
    guard case .branded(let first) = everyday.first, case .survey(let last) = everyday.last
    else {
      Issue.record("Expected Branded first and Survey last, got \(everyday)")
      return
    }
    #expect(first.fdcID == 2_617_100)
    #expect(last.description == "Abalone")
    try expectAuthenticatedRequests(
      transport,
      path: "/fdc/v1/foods?fdcIds=2617100,2768188,167782,2706337,999999999&format=full")
  }

  @Test("All abridged multiple-food entry points send equivalent authenticated requests")
  func allAbridgedMultipleFoodEntryPointsSendEquivalentAuthenticatedRequests() async throws {
    let body = try Fixture.foodsAbridged.data()
    let transport = MockTransport(results: Array(repeating: .success(.ok(json: body)), count: 3))
    let client = try makeClient(transport)
    let ids = try FoodIDs([2_617_100, 2_768_188])
    let everyday = try await client.abridgedFoods(ids)
    let reusable = try await client.value(for: .abridgedFoods(ids))
    let endpoint = try await client.send(.abridgedFoods(ids))
    #expect(everyday == reusable)
    #expect(reusable == endpoint)
    #expect(everyday.map(\.fdcID) == [2_768_188, 2_617_100])
    try expectAuthenticatedRequests(
      transport, path: "/fdc/v1/foods?fdcIds=2617100,2768188&format=abridged")
  }

  @Test("An empty response returns no foods")
  func anEmptyResponseReturnsNoFoods() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Data("[]".utf8))), .success(.ok(json: Data("[]".utf8))),
    ])
    let client = try makeClient(transport)
    let ids = try FoodIDs([1, 2])
    #expect(try await client.foods(ids).isEmpty)
    #expect(try await client.abridgedFoods(ids).isEmpty)
    #expect(transport.requests.count == 2)
  }

  @Test("A recorded empty object returns no foods from every entry point")
  func aRecordedEmptyObjectReturnsNoFoodsFromEveryEntryPoint() async throws {
    let body = try Fixture.foodsAllInvalid.data()
    let transport = MockTransport(results: Array(repeating: .success(.ok(json: body)), count: 4))
    let client = try makeClient(transport)
    let ids = try FoodIDs([999_999_998, 999_999_999])
    #expect(try await client.foods(ids).isEmpty)
    #expect(try await client.abridgedFoods(ids).isEmpty)
    #expect(try await client.value(for: .foods(ids)).isEmpty)
    #expect(try await client.send(.abridgedFoods(ids)).isEmpty)
    #expect(transport.requests.count == 4)
  }

  @Test("A non-empty object fails as a decoding failure", arguments: [false, true])
  func aNonEmptyObjectFailsAsADecodingFailure(_ abridged: Bool) async throws {
    let transport = MockTransport(results: [.success(.ok(json: Data(#"{"a":1}"#.utf8)))])
    let client = try makeClient(transport)
    let ids = try FoodIDs([167_782])
    do throws(FoodDataCentralError) {
      if abridged {
        _ = try await client.abridgedFoods(ids)
      } else {
        _ = try await client.foods(ids)
      }
      Issue.record("A non-empty object must fail to decode.")
    } catch {
      guard case .transport(.decode) = error else {
        Issue.record("Expected a typed decoding failure, received \(error).")
        return
      }
    }
  }

  @Test("An identifier count outside one to twenty fails before any request", arguments: [0, 21])
  func anIdentifierCountOutsideOneToTwentyFailsBeforeAnyRequest(_ count: Int) async throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    do {
      let ids = try FoodIDs((0..<count).map { FoodID(167_782 + $0) })
      _ = try await client.foods(ids)
      Issue.record("An out-of-range identifier count must be rejected.")
    } catch let error as FoodDataCentralValidationError {
      #expect(error == .foodIDCount(count))
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("A repeated identifier fails before any request")
  func aRepeatedIdentifierFailsBeforeAnyRequest() async throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    do {
      let ids = try FoodIDs([167_782, 2_768_188, 167_782])
      _ = try await client.foods(ids)
      Issue.record("A repeated identifier must be rejected.")
    } catch let error as FoodDataCentralValidationError {
      #expect(error == .duplicateFoodID(167_782))
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("A rejected request without a gateway body remains an HTTP failure")
  func aRejectedRequestWithoutAGatewayBodyRemainsAnHTTPFailure() async throws {
    // Recorded from `/food/abc`; the mapping depends only on the body not being the api.data.gov
    // error shape.
    let body = try Fixture.foodInvalidID.data()
    let transport = MockTransport(results: [.success(Response(body: body, status: .badRequest))])
    let ids = try FoodIDs([167_782])
    do {
      _ = try await makeClient(transport).foods(ids)
      Issue.record("The HTTP failure must be thrown.")
    } catch {
      guard case .transport(.httpStatus(let received, let status, _)) = error else {
        Issue.record("Expected the original HTTP failure, received \(error).")
        return
      }
      #expect(status == 400)
      #expect(received == body)
    }
    #expect(transport.requests.count == 1)
  }

  @Test("Cancellation before a multiple-food lookup sends nothing", arguments: [false, true])
  func cancellationBeforeAMultipleFoodLookupSendsNothing(_ abridged: Bool) async throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    let ids = try FoodIDs([167_782])
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        do throws(FoodDataCentralError) {
          if abridged {
            _ = try await client.abridgedFoods(ids)
          } else {
            _ = try await client.foods(ids)
          }
          Issue.record("Cancellation must fail the lookup.")
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

  private func expectAuthenticatedRequests(_ transport: MockTransport, path: String) throws {
    let field = try #require(HTTPField.Name("X-Api-Key"))
    #expect(transport.requests.count == 3)
    for call in transport.requests {
      #expect(call.request.method == .get)
      #expect(call.request.authority == "api.nal.usda.gov")
      #expect(call.request.path == path)
      #expect(call.request.headerFields[field] == "private-test-key")
      #expect(call.request.path?.lowercased().contains("api_key") == false)
      #expect(call.body == .none)
    }
  }

  private func makeClient(
    _ transport: MockTransport
  ) throws(FoodDataCentralError) -> FoodDataCentralClient {
    FoodDataCentralClient(
      configuration: try FoodDataCentralConfiguration(apiKey: "private-test-key"),
      transport: transport)
  }
}
