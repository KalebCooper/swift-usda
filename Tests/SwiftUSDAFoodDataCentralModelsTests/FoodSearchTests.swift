import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

/// A response shape a consumer defines for a search endpoint of their own.
private struct HitCount: Decodable, Sendable {
  let totalHits: Int
}

extension FoodRequest where Response == FoodSearchResult {
  /// A consumer-defined named factory built from the library's query.
  fileprivate static func brandedFoods(matching text: String) throws -> Self {
    .foodSearch(try FoodSearchQuery(text, dataTypes: [.branded], pageSize: 200))
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodSearchTests {
  // A page shaped like the specification's `SearchResult`, with a key it does not list.
  private static let pageBody = Data(
    #"""
    {
      "foodSearchCriteria": {
        "query": "cheddar cheese",
        "dataType": ["Branded", "SR Legacy"],
        "pageSize": 2,
        "pageNumber": 1,
        "sortBy": "dataType.keyword",
        "sortOrder": "asc",
        "brandOwner": "Kar Nut Products Company",
        "tradeChannel": ["GROCERY"],
        "startDate": "2021-01-01",
        "endDate": "2021-12-30"
      },
      "totalHits": 3,
      "currentPage": 1,
      "totalPages": 2,
      "foods": [
        {
          "fdcId": 45001529,
          "dataType": "Branded",
          "description": "CHEDDAR CHEESE",
          "foodNutrients": [
            {
              "number": 303,
              "name": "Iron, Fe",
              "amount": 0.53,
              "unitName": "mg",
              "derivationCode": "LCCD",
              "derivationDescription": "Calculated from a daily value percentage per serving size measure"
            }
          ],
          "publicationDate": "4/1/2019",
          "brandOwner": "Supervalu, Inc.",
          "gtinUpc": "041303020937",
          "ingredients": "CHEDDAR CHEESE (PASTEURIZED MILK, SALT, ENZYMES)",
          "allHighlightFields": "",
          "score": 812.5,
          "unlistedKey": true
        },
        {
          "fdcId": 170899,
          "dataType": "SR Legacy",
          "description": "Cheese, cheddar",
          "foodCode": null,
          "ndbNumber": 1009,
          "additionalDescriptions": "Coon; sharp cheese",
          "scientificName": null,
          "score": 640.25
        }
      ]
    }
    """#.utf8)

  @Test("A default query posts the first page of fifty with no filter or sort")
  func aDefaultQueryPostsTheFirstPageOfFiftyWithNoFilterOrSort() throws {
    let endpoint = Endpoint.foodSearch(try FoodSearchQuery("cheddar cheese"))
    #expect(endpoint.method == .post)
    #expect(endpoint.path == "/foods/search")
    #expect(
      endpoint.body == Data(#"{"pageNumber":1,"pageSize":50,"query":"cheddar cheese"}"#.utf8))
  }

  @Test("A full query encodes every body field with sorted keys and sorted sets")
  func aFullQueryEncodesEveryBodyFieldWithSortedKeysAndSortedSets() throws {
    let query = try FoodSearchQuery(
      "cheddar/swiss \"aged\"", brandOwner: "Kar Nut Products Company",
      dataTypes: [.survey, .branded, .srLegacy],
      endDate: FoodPublicationDate(year: 2021, month: 12, day: 30), pageNumber: 3, pageSize: 25,
      sort: FoodSort(field: .description, order: .descending),
      startDate: FoodPublicationDate(year: 2021, month: 1, day: 1),
      tradeChannels: [.vending, .childNutritionFoodPrograms, .grocery])
    let expected =
      #"{"brandOwner":"Kar Nut Products Company","dataType":["Branded","SR Legacy","Survey (FNDDS)"],"#
      + #""endDate":"2021-12-30","pageNumber":3,"pageSize":25,"query":"cheddar/swiss \"aged\"","#
      + #""sortBy":"lowercaseDescription.keyword","sortOrder":"desc","startDate":"2021-01-01","#
      + #""tradeChannel":["CHILD_NUTRITION_FOOD_PROGRAMS","GROCERY","VENDING"]}"#
    #expect(Endpoint.foodSearch(query).body == Data(expected.utf8))
  }

  @Test("Equal queries built in different orders encode the same bytes")
  func equalQueriesBuiltInDifferentOrdersEncodeTheSameBytes() throws {
    let first = try FoodSearchQuery(
      "apple", dataTypes: [.foundation, .branded], tradeChannels: [.online, .drug])
    let second = try FoodSearchQuery(
      "apple", dataTypes: [.branded, .foundation], tradeChannels: [.drug, .online])
    #expect(Endpoint.foodSearch(first) == Endpoint.foodSearch(second))
    #expect(Endpoint.foodSearch(first).body == Endpoint.foodSearch(second).body)
  }

  @Test("A sort without an order sends no sort order")
  func aSortWithoutAnOrderSendsNoSortOrder() throws {
    let query = try FoodSearchQuery("apple", sort: FoodSort(field: .fdcID))
    #expect(
      Endpoint.foodSearch(query).body
        == Data(#"{"pageNumber":1,"pageSize":50,"query":"apple","sortBy":"fdcId"}"#.utf8))
  }

  @Test("Query text is sent exactly as given, surrounding spaces included")
  func queryTextIsSentExactlyAsGivenSurroundingSpacesIncluded() throws {
    let query = try FoodSearchQuery("  apple  ")
    #expect(query.query == "  apple  ")
    #expect(
      Endpoint.foodSearch(query).body
        == Data(#"{"pageNumber":1,"pageSize":50,"query":"  apple  "}"#.utf8))
  }

  @Test("Empty or whitespace-only query text is rejected", arguments: ["", " ", "\n\t "])
  func emptyOrWhitespaceOnlyQueryTextIsRejected(text: String) {
    #expect(throws: FoodDataCentralValidationError.emptySearchQuery) {
      try FoodSearchQuery(text)
    }
  }

  @Test("A page number below one is rejected")
  func aPageNumberBelowOneIsRejected() {
    #expect(throws: FoodDataCentralValidationError.pageNumber(0)) {
      try FoodSearchQuery("apple", pageNumber: 0)
    }
  }

  @Test("A page size outside one to two hundred is rejected", arguments: [0, 201])
  func aPageSizeOutsideOneToTwoHundredIsRejected(size: Int) {
    #expect(throws: FoodDataCentralValidationError.pageSize(size)) {
      try FoodSearchQuery("apple", pageSize: size)
    }
  }

  @Test("More than three trade channels are rejected")
  func moreThanThreeTradeChannelsAreRejected() {
    #expect(throws: FoodDataCentralValidationError.tradeChannelCount(4)) {
      try FoodSearchQuery("apple", tradeChannels: [.drug, .grocery, .online, .vending])
    }
  }

  @Test("A start date after the end date is rejected")
  func aStartDateAfterTheEndDateIsRejected() throws {
    let start = try FoodPublicationDate(year: 2022, month: 3, day: 2)
    let end = try FoodPublicationDate(year: 2022, month: 3, day: 1)
    #expect(throws: FoodDataCentralValidationError.publicationDateRange(start: start, end: end)) {
      try FoodSearchQuery("apple", endDate: end, startDate: start)
    }
  }

  @Test("A start date equal to the end date is accepted")
  func aStartDateEqualToTheEndDateIsAccepted() throws {
    let day = try FoodPublicationDate(year: 2022, month: 3, day: 1)
    let query = try FoodSearchQuery("apple", endDate: day, startDate: day)
    #expect(query.startDate == query.endDate)
  }

  @Test(
    "A date that names no Gregorian day is rejected",
    arguments: [
      (2023, 2, 29), (1900, 2, 29), (2022, 4, 31), (2022, 13, 1), (2022, 1, 0), (0, 1, 1),
      (10_000, 1, 1),
    ])
  func aDateThatNamesNoGregorianDayIsRejected(year: Int, month: Int, day: Int) {
    #expect(
      throws: FoodDataCentralValidationError.publicationDate(year: year, month: month, day: day)
    ) {
      try FoodPublicationDate(year: year, month: month, day: day)
    }
  }

  @Test("A leap day and a short year are written as four, two, and two digits")
  func aLeapDayAndAShortYearAreWrittenAsFourTwoAndTwoDigits() throws {
    #expect(try FoodPublicationDate(year: 2024, month: 2, day: 29).description == "2024-02-29")
    #expect(try FoodPublicationDate(year: 2000, month: 2, day: 29).description == "2000-02-29")
    #expect(try FoodPublicationDate(year: 5, month: 1, day: 9).description == "0005-01-09")
  }

  @Test("A page decodes its totals, echoed criteria, foods, and nutrients")
  func aPageDecodesItsTotalsEchoedCriteriaFoodsAndNutrients() throws {
    let page = try JSONDecoder().decode(FoodSearchResult.self, from: Self.pageBody)
    #expect(page.totalHits == 3)
    #expect(page.currentPage == 1)
    #expect(page.totalPages == 2)
    #expect(
      page.foodSearchCriteria
        == FoodSearchCriteria(
          brandOwner: "Kar Nut Products Company", dataType: [.branded, .srLegacy],
          endDate: "2021-12-30", pageNumber: 1, pageSize: 2, query: "cheddar cheese",
          sortBy: "dataType.keyword", sortOrder: "asc", startDate: "2021-01-01",
          tradeChannel: [.grocery]))
    #expect(
      page.foods.first
        == SearchResultFood(
          allHighlightFields: "", brandOwner: "Supervalu, Inc.", dataType: .branded,
          description: "CHEDDAR CHEESE", fdcID: 45_001_529,
          foodNutrients: [
            SearchResultFoodNutrient(
              amount: 0.53, derivationCode: "LCCD",
              derivationDescription:
                "Calculated from a daily value percentage per serving size measure",
              name: "Iron, Fe", number: "303", unitName: "mg")
          ],
          gtinUpc: "041303020937", ingredients: "CHEDDAR CHEESE (PASTEURIZED MILK, SALT, ENZYMES)",
          publicationDate: "4/1/2019", score: 812.5))
    #expect(
      page.foods.last
        == SearchResultFood(
          additionalDescriptions: "Coon; sharp cheese", dataType: .srLegacy,
          description: "Cheese, cheddar", fdcID: 170_899, ndbNumber: "1009", score: 640.25))
  }

  @Test("A string NDB number and nutrient number are kept as given")
  func aStringNDBNumberAndNutrientNumberAreKeptAsGiven() throws {
    let food = try JSONDecoder().decode(
      SearchResultFood.self,
      from: Data(
        #"{"fdcId":1,"description":"x","ndbNumber":"01009","foodNutrients":[{"number":"203"}]}"#
          .utf8))
    #expect(food.ndbNumber == "01009")
    #expect(food.foodNutrients == [SearchResultFoodNutrient(number: "203")])
    #expect(food.dataType == nil)
  }

  @Test("A food in the service's spelling decodes its nutrients and publication date")
  func aFoodInTheServicesSpellingDecodesItsNutrientsAndPublicationDate() throws {
    let body = #"""
      {"fdcId":1,"description":"x","publishedDate":"2019-04-01","foodNutrients":[
      {"nutrientId":1089,"nutrientName":"Iron, Fe","nutrientNumber":"303","unitName":"MG",
      "value":0.53}]}
      """#
    let food = try JSONDecoder().decode(SearchResultFood.self, from: Data(body.utf8))
    #expect(food.publicationDate == "2019-04-01")
    #expect(
      food.foodNutrients == [
        SearchResultFoodNutrient(
          amount: 0.53, name: "Iron, Fe", nutrientID: 1089, number: "303", unitName: "MG")
      ])
  }

  @Test("A food in the specification's spelling decodes its nutrients and publication date")
  func aFoodInTheSpecificationsSpellingDecodesItsNutrientsAndPublicationDate() throws {
    let body = #"""
      {"fdcId":1,"description":"x","publicationDate":"4/1/2019","foodNutrients":[
      {"name":"Iron, Fe","number":303,"unitName":"mg","amount":0.53}]}
      """#
    let food = try JSONDecoder().decode(SearchResultFood.self, from: Data(body.utf8))
    #expect(food.publicationDate == "4/1/2019")
    #expect(
      food.foodNutrients == [
        SearchResultFoodNutrient(amount: 0.53, name: "Iron, Fe", number: "303", unitName: "mg")
      ])
  }

  @Test("When both spellings appear, the service's spelling wins")
  func whenBothSpellingsAppearTheServicesSpellingWins() throws {
    let body = #"""
      {"fdcId":1,"description":"x","publicationDate":"4/1/2019","publishedDate":"2019-04-01",
      "foodNutrients":[{"amount":1.5,"value":0.53,"name":"Iron","nutrientName":"Iron, Fe",
      "number":"999","nutrientNumber":303,"unitName":"mg"}]}
      """#
    let food = try JSONDecoder().decode(SearchResultFood.self, from: Data(body.utf8))
    #expect(food.publicationDate == "2019-04-01")
    #expect(
      food.foodNutrients == [
        SearchResultFoodNutrient(amount: 0.53, name: "Iron, Fe", number: "303", unitName: "mg")
      ])
  }

  @Test("A search food encodes in the service's spelling")
  func aSearchFoodEncodesInTheServicesSpelling() throws {
    let food = SearchResultFood(
      description: "x", fdcID: 1,
      foodNutrients: [
        SearchResultFoodNutrient(
          amount: 0.53, name: "Iron, Fe", nutrientID: 1089, number: "303", unitName: "mg")
      ],
      publicationDate: "4/1/2019")
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let json = String(decoding: try encoder.encode(food), as: UTF8.self)
    #expect(
      json
        == #"{"description":"x","fdcId":1,"foodNutrients":[{"nutrientId":1089,"#
        + #""nutrientName":"Iron, Fe","nutrientNumber":"303","unitName":"mg","value":0.53}],"#
        + #""publishedDate":"4/1/2019"}"#)
  }

  @Test("A malformed criteria echo is dropped and the page still decodes")
  func aMalformedCriteriaEchoIsDroppedAndThePageStillDecodes() throws {
    let body = #"""
      {"foodSearchCriteria":{"query":["not","a","string"],"pageSize":"two"},
      "totalHits":1,"currentPage":1,"totalPages":1,
      "foods":[{"fdcId":7,"description":"Apple"}]}
      """#
    let page = try JSONDecoder().decode(FoodSearchResult.self, from: Data(body.utf8))
    #expect(page.foodSearchCriteria == nil)
    #expect(page.totalHits == 1)
    #expect(page.currentPage == 1)
    #expect(page.totalPages == 1)
    #expect(page.foods == [SearchResultFood(description: "Apple", fdcID: 7)])
  }

  @Test("A search food without a description fails to decode")
  func aSearchFoodWithoutADescriptionFailsToDecode() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(SearchResultFood.self, from: Data(#"{"fdcId":1}"#.utf8))
    }
  }

  @Test("A page without its totals fails to decode")
  func aPageWithoutItsTotalsFailsToDecode() {
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode(FoodSearchResult.self, from: Data(#"{"foods":[]}"#.utf8))
    }
  }

  @Test("A page survives an encode and decode round trip")
  func aPageSurvivesAnEncodeAndDecodeRoundTrip() throws {
    let page = try JSONDecoder().decode(FoodSearchResult.self, from: Self.pageBody)
    let again = try JSONDecoder().decode(
      FoodSearchResult.self, from: try JSONEncoder().encode(page))
    #expect(again == page)
  }

  @Test("A page before the last continues at the next page with every filter kept")
  func aPageBeforeTheLastContinuesAtTheNextPageWithEveryFilterKept() throws {
    let start = try FoodPublicationDate(year: 2021, month: 1, day: 1)
    let query = try FoodSearchQuery(
      "cheddar cheese", brandOwner: "Kar Nut Products Company", dataTypes: [.branded, .srLegacy],
      pageSize: 2, sort: FoodSort(field: .dataType, order: .ascending), startDate: start,
      tradeChannels: [.grocery])
    let page = try JSONDecoder().decode(FoodSearchResult.self, from: Self.pageBody)
    let next = try #require(try query.next(after: page))
    #expect(
      next
        == (try FoodSearchQuery(
          "cheddar cheese", brandOwner: "Kar Nut Products Company",
          dataTypes: [.branded, .srLegacy], pageNumber: 2, pageSize: 2,
          sort: FoodSort(field: .dataType, order: .ascending), startDate: start,
          tradeChannels: [.grocery])))
  }

  @Test("The last page ends the search")
  func theLastPageEndsTheSearch() throws {
    let query = try FoodSearchQuery("apple", pageNumber: 2, pageSize: 2)
    let page = Self.page(current: 2, foods: 1, hits: 3, pages: 2)
    #expect(try query.next(after: page) == nil)
  }

  @Test("A search with no hits is one empty page")
  func aSearchWithNoHitsIsOneEmptyPage() throws {
    let query = try FoodSearchQuery("zzzzqqqq")
    let page = try JSONDecoder().decode(
      FoodSearchResult.self,
      from: Data(#"{"totalHits":0,"currentPage":1,"totalPages":0,"foods":[]}"#.utf8))
    #expect(try query.next(after: page) == nil)
  }

  @Test("A page reporting another page number is rejected, including a repeated page")
  func aPageReportingAnotherPageNumberIsRejectedIncludingARepeatedPage() throws {
    let query = try FoodSearchQuery("apple", pageNumber: 2, pageSize: 2)
    #expect(throws: FoodPaginationError.unexpectedPageNumber(actual: 1, expected: 2)) {
      try query.next(after: Self.page(current: 1, foods: 2, hits: 6, pages: 3))
    }
  }

  @Test("A page holding more foods than its size is rejected")
  func aPageHoldingMoreFoodsThanItsSizeIsRejected() throws {
    let query = try FoodSearchQuery("apple", pageSize: 1)
    #expect(throws: FoodPaginationError.excessFoods(count: 2, pageSize: 1)) {
      try query.next(after: Self.page(current: 1, foods: 2, hits: 6, pages: 3))
    }
  }

  @Test(
    "Totals that contradict each other or the page are rejected",
    arguments: [(-1, 1, 0), (1, -1, 0), (0, 1, 0), (5, 0, 0), (1, 1, 2)])
  func totalsThatContradictEachOtherOrThePageAreRejected(hits: Int, pages: Int, foods: Int)
    throws
  {
    let query = try FoodSearchQuery("apple", pageSize: 2)
    #expect(throws: FoodPaginationError.inconsistentTotals(totalHits: hits, totalPages: pages)) {
      try query.next(after: Self.page(current: 1, foods: foods, hits: hits, pages: pages))
    }
  }

  @Test("A page count is not checked against the hit count and page size")
  func aPageCountIsNotCheckedAgainstTheHitCountAndPageSize() throws {
    let query = try FoodSearchQuery("apple", pageSize: 2)
    let next = try query.next(after: Self.page(current: 1, foods: 2, hits: 2, pages: 5))
    #expect(next?.pageNumber == 2)
  }

  @Test("A contextual factory resolves to the search query")
  func aContextualFactoryResolvesToTheSearchQuery() throws {
    let query = try FoodSearchQuery("apple")
    let request: FoodRequest<FoodSearchResult> = .foodSearch(query)
    #expect(request.resolution == .foodSearch(query))
  }

  @Test("An unannotated stored search request infers its response type")
  func anUnannotatedStoredSearchRequestInfersItsResponseType() throws {
    let request = FoodRequest.foodSearch(try FoodSearchQuery("apple"))
    let typed: FoodRequest<FoodSearchResult> = request
    #expect(typed == FoodRequest.foodSearch(try FoodSearchQuery("apple")))
  }

  @Test("A consumer-defined factory composes the library's search query")
  func aConsumerDefinedFactoryComposesTheLibrarysSearchQuery() throws {
    let request = try FoodRequest.brandedFoods(matching: "apple")
    #expect(
      request.resolution
        == .foodSearch(try FoodSearchQuery("apple", dataTypes: [.branded], pageSize: 200)))
  }

  @Test("A consumer-defined response wraps a GET search endpoint with no body")
  func aConsumerDefinedResponseWrapsAGETSearchEndpointWithNoBody() throws {
    let endpoint = try #require(Endpoint<HitCount>(path: "/foods/search?query=apple"))
    #expect(endpoint.method == .get)
    #expect(endpoint.body == nil)
    let request = FoodRequest(endpoint: endpoint)
    #expect(request.resolution == .endpoint(endpoint))
    let count = try JSONDecoder().decode(HitCount.self, from: Self.pageBody)
    #expect(count.totalHits == 3)
  }

  @Test("Path and link endpoints are GET requests with no body")
  func pathAndLinkEndpointsAreGETRequestsWithNoBody() throws {
    let path = try #require(Endpoint<FoodSearchResult>(path: "/foods/search"))
    let url = try #require(URL(string: "https://api.nal.usda.gov/fdc/v1/foods/search"))
    let link = try #require(Endpoint<FoodSearchResult>(link: url))
    for endpoint in [path, link] {
      #expect(endpoint.method == .get)
      #expect(endpoint.body == nil)
      #expect(endpoint != Endpoint.foodSearch(try FoodSearchQuery("apple")))
    }
  }

  @Test("Trade channel constants use the specification's wire names")
  func tradeChannelConstantsUseTheSpecificationsWireNames() {
    #expect(
      [
        TradeChannel.childNutritionFoodPrograms, .drug, .foodService, .grocery,
        .massMerchandising, .military, .online, .vending,
      ].map(\.rawValue) == [
        "CHILD_NUTRITION_FOOD_PROGRAMS", "DRUG", "FOOD_SERVICE", "GROCERY", "MASS_MERCHANDISING",
        "MILITARY", "ONLINE", "VENDING",
      ])
  }

  private static func page(current: Int, foods: Int, hits: Int, pages: Int) -> FoodSearchResult {
    FoodSearchResult(
      currentPage: current,
      foods: (0..<foods).map { SearchResultFood(description: "Food \($0)", fdcID: FoodID($0 + 1)) },
      totalHits: hits, totalPages: pages)
  }
}
