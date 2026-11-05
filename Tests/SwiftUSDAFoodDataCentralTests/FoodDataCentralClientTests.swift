import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite("FoodData Central client", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodDataCentralClientTests {
  @Test("All full food entry points send equivalent authenticated requests")
  func allFullFoodEntryPointsSendEquivalentAuthenticatedRequests() async throws {
    let body = try Fixture.foodFoundationFull.data()
    let transport = MockTransport(results: Array(repeating: .success(.ok(json: body)), count: 3))
    let client = try makeClient(transport)
    let nutrients = try NutrientNumbers([203, 204, 205])
    let everyday = try await client.food(2_768_188, nutrients: nutrients)
    let reusable = try await client.value(for: .food(2_768_188, nutrients: nutrients))
    let endpoint = try await client.send(.food(2_768_188, nutrients: nutrients))
    #expect(everyday == reusable)
    #expect(reusable == endpoint)
    guard case .foundation(let food) = everyday else {
      Issue.record("Expected a Foundation food, got \(everyday)")
      return
    }
    #expect(food.description == "Alaska Pollock, raw")
    #expect(food.ndbNumber == "15266")
    #expect(food.foodNutrients?.count == 105)
    try expectAuthenticatedRequests(
      transport, path: "/fdc/v1/food/2768188?format=full&nutrients=203,204,205")
  }

  @Test("All abridged food entry points send equivalent authenticated requests")
  func allAbridgedFoodEntryPointsSendEquivalentAuthenticatedRequests() async throws {
    let body = try Fixture.foodFoundationAbridged.data()
    let transport = MockTransport(results: Array(repeating: .success(.ok(json: body)), count: 3))
    let client = try makeClient(transport)
    let everyday = try await client.abridgedFood(2_768_188)
    let reusable = try await client.value(for: .abridgedFood(2_768_188))
    let endpoint = try await client.send(.abridgedFood(2_768_188))
    #expect(everyday == reusable)
    #expect(reusable == endpoint)
    #expect(everyday.fdcID == 2_768_188)
    #expect(everyday.ndbNumber == "15266")
    #expect(everyday.foodNutrients.first?.number == "855")
    try expectAuthenticatedRequests(transport, path: "/fdc/v1/food/2768188?format=abridged")
  }

  @Test("Cancellation before any entry point sends nothing", arguments: EntryPoint.allCases)
  func cancellationBeforeAnyEntryPointSendsNothing(_ entry: EntryPoint) async throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        do throws(FoodDataCentralError) {
          switch entry {
          case .abridgedFood: _ = try await client.abridgedFood(2_768_188)
          case .food: _ = try await client.food(2_768_188)
          case .send: _ = try await client.send(.food(2_768_188))
          case .value: _ = try await client.value(for: .food(2_768_188))
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

  @Test("Configuration descriptions redact the credential")
  func configurationDescriptionsRedactTheCredential() throws {
    let configuration = try FoodDataCentralConfiguration(apiKey: "private-test-key")
    #expect(!String(describing: configuration).contains("private-test-key"))
    #expect(!String(reflecting: configuration).contains("private-test-key"))
  }

  @Test("Consumer defined responses execute through reusable requests")
  func consumerDefinedResponsesExecuteThroughReusableRequests() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.foodFoundationFull.data()))
    ])
    let endpoint = try #require(Endpoint<FoodName>(path: "/food/2768188?format=full"))
    let response = try await makeClient(transport).value(for: FoodRequest(endpoint: endpoint))
    #expect(response.description == "Alaska Pollock, raw")
    #expect(transport.requests.first?.request.path == "/fdc/v1/food/2768188?format=full")
  }

  @Test(
    "Recorded gateway credential failures keep their code and HTTP metadata",
    arguments: [
      (Fixture.authInvalidKey, "API_KEY_INVALID"), (Fixture.authMissingKey, "API_KEY_MISSING"),
    ])
  func recordedGatewayCredentialFailuresKeepTheirCodeAndHTTPMetadata(
    _ fixture: Fixture, _ code: String
  ) async throws {
    let body = try fixture.data()
    let transport = MockTransport(results: [.success(Response(body: body, status: .forbidden))])
    do {
      _ = try await makeClient(transport).food(2_768_188)
      Issue.record("A gateway failure must be thrown.")
    } catch {
      guard case .gateway(let response, let failure) = error,
        case .httpStatus(let received, let status, _) = failure
      else {
        Issue.record("Expected a typed gateway response, received \(error).")
        return
      }
      #expect(response.error.code == code)
      #expect(received == body)
      #expect(status == 403)
    }
    #expect(transport.requests.count == 1)
  }

  @Test("Rate limiting maps to the gateway error without retrying")
  func rateLimitingMapsToTheGatewayErrorWithoutRetrying() async throws {
    // The body the api.data.gov manual documents for this code; it is not recorded, because
    // recording it would exhaust a real key.
    let body = Data(
      #"{"error":{"code":"OVER_RATE_LIMIT","message":"You have exceeded your rate limit. Try again later or contact us at https://api.data.gov:443/contact/ for assistance"}}"#
        .utf8)
    let transport = MockTransport(results: [
      .success(
        Response(body: body, headers: [.retryAfter: "3600"], status: .tooManyRequests))
    ])
    do {
      _ = try await makeClient(transport).abridgedFood(2_768_188)
      Issue.record("Rate limiting must be returned to the caller.")
    } catch {
      guard case .gateway(let response, let failure) = error,
        case .httpStatus(_, let status, let headers) = failure
      else {
        Issue.record("Expected the gateway error and HTTP metadata, received \(error).")
        return
      }
      #expect(response.error.code == "OVER_RATE_LIMIT")
      #expect(status == 429)
      #expect(headers[.retryAfter] == "3600")
    }
    #expect(transport.requests.count == 1)
  }

  @Test(
    "Invalid API keys fail without retaining the rejected credential",
    arguments: ["", " ", " key", "key ", "key\nvalue", "key\rvalue", "key\tvalue", "clé"])
  func invalidAPIKeysFailWithoutRetainingTheRejectedCredential(_ key: String) {
    do {
      _ = try FoodDataCentralConfiguration(apiKey: key)
      Issue.record("Invalid configuration must fail.")
    } catch {
      guard case .invalidAPIKey = error else {
        Issue.record("Expected invalidAPIKey.")
        return
      }
    }
  }

  @Test("Malformed successful bodies produce typed decoding failures")
  func malformedSuccessfulBodiesProduceTypedDecodingFailures() async throws {
    let transport = MockTransport(results: [.success(.ok(json: Data("not JSON".utf8)))])
    do {
      _ = try await makeClient(transport).food(2_768_188)
      Issue.record("An invalid response must fail decoding.")
    } catch {
      guard case .transport(.decode) = error else {
        Issue.record("Expected a typed decoding failure, received \(error).")
        return
      }
    }
  }

  @Test(
    "Redirect responses are never followed with credentials",
    arguments: ["https://example.com/collect", "https://api.nal.usda.gov/fdc/v1/food/1"])
  func redirectResponsesAreNeverFollowedWithCredentials(_ location: String) async throws {
    let transport = MockTransport(results: [
      .success(Response(headers: [.location: location], status: .found)),
      .success(.ok(json: try Fixture.foodFoundationFull.data())),
    ])
    do {
      _ = try await makeClient(transport).food(2_768_188)
      Issue.record("A redirect must be returned as a failure.")
    } catch {
      guard case .transport(.httpStatus(_, let status, _)) = error else {
        Issue.record("Expected an HTTP redirect failure, received \(error).")
        return
      }
      #expect(status == 302)
    }
    #expect(transport.requests.count == 1)
  }

  @Test("Unrecognized HTTP bodies remain inspectable", arguments: [400, 403, 404, 429, 500])
  func unrecognizedHTTPBodiesRemainInspectable(_ status: Int) async throws {
    let body = Data("<html>Unavailable</html>".utf8)
    let transport = MockTransport(results: [
      .success(Response(body: body, status: .init(code: status)))
    ])
    do {
      _ = try await makeClient(transport).food(2_768_188)
      Issue.record("The HTTP failure must be thrown.")
    } catch {
      guard case .transport(.httpStatus(let received, let code, _)) = error else {
        Issue.record("Expected the original HTTP failure, received \(error).")
        return
      }
      #expect(code == status)
      #expect(received == body)
    }
    #expect(transport.requests.count == 1)
  }

  private func expectAuthenticatedRequests(_ transport: MockTransport, path: String) throws {
    let field = try #require(HTTPField.Name("X-Api-Key"))
    #expect(transport.requests.count == 3)
    for call in transport.requests {
      #expect(call.request.method == .get)
      #expect(call.request.scheme == "https")
      #expect(call.request.authority == "api.nal.usda.gov")
      #expect(call.request.path == path)
      #expect(call.request.headerFields[.accept] == "application/json")
      #expect(call.request.headerFields[field] == "private-test-key")
      #expect(call.request.path?.contains("private-test-key") == false)
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

// The client entry points that send a request, one per public lookup level.
enum EntryPoint: CaseIterable, Sendable {
  case abridgedFood
  case food
  case send
  case value
}

private struct FoodName: Decodable, Sendable {
  let description: String
}
