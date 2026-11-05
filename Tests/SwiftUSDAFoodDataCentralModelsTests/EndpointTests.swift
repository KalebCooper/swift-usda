import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct EndpointTests {
  @Test("A full food lookup names the full format")
  func aFullFoodLookupNamesTheFullFormat() {
    #expect(Endpoint<Food>.food(2_346_404).path == "/food/2346404?format=full")
  }

  @Test("An abridged lookup sends its nutrients comma-separated in the order given")
  func anAbridgedLookupSendsItsNutrientsCommaSeparatedInTheOrderGiven() throws {
    let endpoint = Endpoint<AbridgedFood>.abridgedFood(
      167_782, nutrients: try NutrientNumbers([205, 203, 204]))
    #expect(endpoint.path == "/food/167782?format=abridged&nutrients=205,203,204")
  }

  @Test("A path is kept exactly as given")
  func aPathIsKeptExactlyAsGiven() {
    #expect(Endpoint<Food>(path: "/food/1?format=full")?.path == "/food/1?format=full")
  }

  @Test(
    "A path carrying a key, an authority, a fragment, or a dot segment is rejected",
    arguments: [
      "/food/1?api_key=DEMO_KEY", "/food/1?format=full&API_KEY=x", "//api.nal.usda.gov/food/1",
      "https://api.nal.usda.gov/fdc/v1/food/1", "/food/1#top", "/food/../foods", "/food/./1",
      "/food/1 2", "food/1", "/food\\1", "/", "/?format=full",
    ])
  func aPathCarryingAKeyAnAuthorityAFragmentOrADotSegmentIsRejected(path: String) {
    #expect(Endpoint<Food>(path: path) == nil)
  }

  @Test("An API link becomes a path below the versioned base")
  func anAPILinkBecomesAPathBelowTheVersionedBase() throws {
    let link = try #require(URL(string: "https://API.nal.usda.gov:443/fdc/v1/food/1?format=full"))
    #expect(Endpoint<Food>(link: link)?.path == "/food/1?format=full")
  }

  @Test(
    "A link to another origin, with credentials, a fragment, or a key is rejected",
    arguments: [
      "https://example.com/fdc/v1/food/1", "http://api.nal.usda.gov/fdc/v1/food/1",
      "https://api.nal.usda.gov:8443/fdc/v1/food/1",
      "https://user:pw@api.nal.usda.gov/fdc/v1/food/1",
      "https://api.nal.usda.gov/fdc/v1/food/1#x",
      "https://api.nal.usda.gov/fdc/v1/food/1?api_key=x",
      "https://api.nal.usda.gov/fdc/v2/food/1", "https://api.nal.usda.gov/food/1",
      "https://api.nal.usda.gov/fdc/v1/", "https://api.nal.usda.gov/fdc/v1/?format=full",
      "https://api.nal.usda.gov/fdc/v1/../x", "https://api.nal.usda.gov/fdc/v1/%2e%2e/x",
      "https://api.nal.usda.gov/fdc/v1/food/1?api%5Fkey=x",
    ])
  func aLinkToAnotherOriginWithCredentialsAFragmentOrAKeyIsRejected(link: String) throws {
    let url = try #require(URL(string: link))
    #expect(Endpoint<Food>(link: url) == nil)
  }

  @Test(
    "A path with an encoded dot segment or an encoded key parameter is rejected",
    arguments: [
      "/food/%2e%2e/foods", "/food/%2E%2E/foods", "/food/%2e/1", "/food/.%2E/foods",
      "/food/1?api%5Fkey=x", "/food/1?API%5FKEY=x", "/food/1?Api%5fKey=x",
      "/food/1?format=full&%61pi_key=x",
    ])
  func aPathWithAnEncodedDotSegmentOrAnEncodedKeyParameterIsRejected(path: String) {
    #expect(Endpoint<Food>(path: path) == nil)
  }
}
