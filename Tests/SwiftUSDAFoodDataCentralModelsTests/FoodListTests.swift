import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

/// A response shape a consumer defines for a list endpoint of their own.
private struct FoodName: Decodable, Sendable {
  let description: String
}

extension FoodRequest where Response == FoodListPage {
  /// A consumer-defined named factory built from the library's query.
  fileprivate static func foundationFoods() throws -> Self {
    .foodList(try FoodListQuery(dataTypes: [.foundation], pageSize: 200))
  }
}

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodListTests {
  @Test("A default query sends the first page of fifty with no filter or sort")
  func aDefaultQuerySendsTheFirstPageOfFiftyWithNoFilterOrSort() throws {
    #expect(Endpoint.foodList(try FoodListQuery()).path == "/foods/list?pageNumber=1&pageSize=50")
  }

  @Test("A full query sends every parameter in name order")
  func aFullQuerySendsEveryParameterInNameOrder() throws {
    let query = try FoodListQuery(
      dataTypes: [.foundation], pageNumber: 3, pageSize: 2,
      sort: FoodSort(field: .fdcID, order: .descending))
    #expect(
      Endpoint.foodList(query).path
        == "/foods/list?dataType=Foundation&pageNumber=3&pageSize=2&sortBy=fdcId&sortOrder=desc")
  }

  @Test("Data types are sent comma-separated in raw-value order and percent-encoded")
  func dataTypesAreSentCommaSeparatedInRawValueOrderAndPercentEncoded() throws {
    let query = try FoodListQuery(dataTypes: [.survey, .srLegacy, .foundation, .branded])
    #expect(
      Endpoint.foodList(query).path
        == "/foods/list?dataType=Branded,Foundation,SR%20Legacy,Survey%20%28FNDDS%29"
        + "&pageNumber=1&pageSize=50")
  }

  @Test("A sort without an order sends no sort order")
  func aSortWithoutAnOrderSendsNoSortOrder() throws {
    let query = try FoodListQuery(sort: FoodSort(field: .publishedDate))
    #expect(
      Endpoint.foodList(query).path
        == "/foods/list?pageNumber=1&pageSize=50&sortBy=publishedDate")
  }

  @Test("Sort fields and orders use today's wire names")
  func sortFieldsAndOrdersUseTodaysWireNames() {
    #expect(FoodSortField.dataType.rawValue == "dataType.keyword")
    #expect(FoodSortField.description.rawValue == "lowercaseDescription.keyword")
    #expect(FoodSortField.fdcID.rawValue == "fdcId")
    #expect(FoodSortField.publishedDate.rawValue == "publishedDate")
    #expect(FoodSortOrder.ascending.rawValue == "asc")
    #expect(FoodSortOrder.descending.rawValue == "desc")
  }

  @Test("The recorded identifier sort returns the highest identifiers first")
  func theRecordedIdentifierSortReturnsTheHighestIdentifiersFirst() throws {
    let query = try FoodListQuery(
      dataTypes: [.foundation], pageSize: 2, sort: FoodSort(field: .fdcID, order: .descending))
    #expect(
      Endpoint.foodList(query).path
        == "/foods/list?dataType=Foundation&pageNumber=1&pageSize=2&sortBy=fdcId&sortOrder=desc")
    let foods = try decodeFoods(.listSortFDCIDDescending)
    #expect(foods.map(\.fdcID) == [2_779_268, 2_779_267])
  }

  @Test("The announced description sort name is rejected by the service")
  func theAnnouncedDescriptionSortNameIsRejectedByTheService() throws {
    #expect(FoodSortField.description.rawValue != "description")
    let body = try JSONDecoder().decode(
      [String: String].self, from: try Fixture.listSortDescription.data())
    #expect(body == ["error": "Bad Request", "message": "Invalid request. Please try again."])
  }

  @Test("The recorded result-window refusal is plain text, not a food array")
  func theRecordedResultWindowRefusalIsPlainTextNotAFoodArray() throws {
    let body = try Fixture.listBeyondEnd.data()
    #expect(
      String(decoding: body, as: UTF8.self)
        == "Bad Request: pageSize * pageNumber exceeded upper search results limit.")
    #expect(throws: DecodingError.self) {
      try JSONDecoder().decode([AbridgedFood].self, from: body)
    }
  }

  @Test("Experimental is accepted as a list filter")
  func experimentalIsAcceptedAsAListFilter() throws {
    let query = try FoodListQuery(dataTypes: [.experimental], pageSize: 2)
    #expect(
      Endpoint.foodList(query).path
        == "/foods/list?dataType=Experimental&pageNumber=1&pageSize=2")
    let foods = try decodeFoods(.listExperimental)
    #expect(foods.allSatisfy { $0.dataType == .experimental })
  }

  @Test("A comma-separated filter decodes the recorded foods")
  func aCommaSeparatedFilterDecodesTheRecordedFoods() throws {
    let foods = try decodeFoods(.listFoundationSRLegacy)
    #expect(foods.map(\.fdcID) == [167_782, 171_687])
    #expect(foods.allSatisfy { $0.dataType == .srLegacy })
  }

  @Test("Page numbers below one are rejected", arguments: [0, -1, Int.min])
  func pageNumbersBelowOneAreRejected(_ pageNumber: Int) {
    #expect(throws: FoodDataCentralValidationError.pageNumber(pageNumber)) {
      try FoodListQuery(pageNumber: pageNumber)
    }
  }

  @Test("Page sizes outside one to two hundred are rejected", arguments: [0, -1, 201])
  func pageSizesOutsideOneToTwoHundredAreRejected(_ pageSize: Int) {
    #expect(throws: FoodDataCentralValidationError.pageSize(pageSize)) {
      try FoodListQuery(pageSize: pageSize)
    }
  }

  @Test("Page sizes of one and two hundred are accepted", arguments: [1, 200])
  func pageSizesOfOneAndTwoHundredAreAccepted(_ pageSize: Int) throws {
    #expect(try FoodListQuery(pageSize: pageSize).pageSize == pageSize)
  }

  @Test("Page zero and page one are recorded as the same page")
  func pageZeroAndPageOneAreRecordedAsTheSamePage() throws {
    #expect(try Fixture.listFoundationPage0.data() == Fixture.listFoundationPage1.data())
  }

  @Test("A full recorded page continues to the next page with every option preserved")
  func aFullRecordedPageContinuesToTheNextPageWithEveryOptionPreserved() throws {
    let sort = FoodSort(field: .fdcID, order: .ascending)
    let first = try FoodListQuery(dataTypes: [.foundation], pageSize: 2, sort: sort)
    let page = FoodListPage(
      foods: try decodeFoods(.listFoundationPage1), pageNumber: 1, pageSize: 2)
    let second = try #require(try first.next(after: page))
    #expect(
      second
        == (try FoodListQuery(dataTypes: [.foundation], pageNumber: 2, pageSize: 2, sort: sort)))
    #expect(
      Endpoint.foodList(second).path
        == "/foods/list?dataType=Foundation&pageNumber=2&pageSize=2&sortBy=fdcId&sortOrder=asc")
  }

  @Test("The recorded second page follows the first without overlap and continues to the third")
  func theRecordedSecondPageFollowsTheFirstWithoutOverlapAndContinuesToTheThird() throws {
    let firstFoods = try decodeFoods(.listFoundationPage1)
    let secondFoods = try decodeFoods(.listFoundationPage2)
    #expect(Set(firstFoods.map(\.fdcID)).isDisjoint(with: secondFoods.map(\.fdcID)))
    let second = try FoodListQuery(dataTypes: [.foundation], pageNumber: 2, pageSize: 2)
    let third = try #require(
      try second.next(after: FoodListPage(foods: secondFoods, pageNumber: 2, pageSize: 2)))
    #expect(
      Endpoint.foodList(third).path == "/foods/list?dataType=Foundation&pageNumber=3&pageSize=2")
  }

  @Test("A short recorded page ends the list")
  func aShortRecordedPageEndsTheList() throws {
    let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 3)
    let page = FoodListPage(foods: try decodeFoods(.listFoundation), pageNumber: 1, pageSize: 3)
    #expect(try query.next(after: page) == nil)
  }

  @Test("An empty page ends the list")
  func anEmptyPageEndsTheList() throws {
    let query = try FoodListQuery(pageNumber: 7, pageSize: 200)
    #expect(try query.next(after: FoodListPage(foods: [], pageNumber: 7, pageSize: 200)) == nil)
  }

  @Test("A page with more foods than its size is rejected")
  func aPageWithMoreFoodsThanItsSizeIsRejected() throws {
    let query = try FoodListQuery(pageSize: 1)
    let page = FoodListPage(foods: try decodeFoods(.listFoundation), pageNumber: 1, pageSize: 1)
    #expect(throws: FoodListPaginationError.excessFoods(count: 2, pageSize: 1)) {
      try query.next(after: page)
    }
  }

  @Test("A page for another page number is rejected")
  func aPageForAnotherPageNumberIsRejected() throws {
    let query = try FoodListQuery(pageNumber: 2, pageSize: 2)
    let page = FoodListPage(foods: try decodeFoods(.listFoundation), pageNumber: 1, pageSize: 2)
    #expect(throws: FoodListPaginationError.unexpectedPageNumber(actual: 1, expected: 2)) {
      try query.next(after: page)
    }
  }

  @Test("A page for another page size is rejected")
  func aPageForAnotherPageSizeIsRejected() throws {
    let query = try FoodListQuery(pageSize: 2)
    let page = FoodListPage(foods: try decodeFoods(.listFoundation), pageNumber: 1, pageSize: 50)
    #expect(throws: FoodListPaginationError.unexpectedPageSize(actual: 50, expected: 2)) {
      try query.next(after: page)
    }
  }

  @Test("A full page at the largest page number throws overflow")
  func aFullPageAtTheLargestPageNumberThrowsOverflow() throws {
    let query = try FoodListQuery(pageNumber: Int.max, pageSize: 2)
    let page = FoodListPage(
      foods: try decodeFoods(.listFoundation), pageNumber: Int.max, pageSize: 2)
    #expect(throws: FoodListPaginationError.pageNumberOverflow) {
      try query.next(after: page)
    }
  }

  @Test("A page round-trips through its own coding")
  func aPageRoundTripsThroughItsOwnCoding() throws {
    let page = FoodListPage(foods: try decodeFoods(.listSurvey), pageNumber: 4, pageSize: 2)
    let decoded = try JSONDecoder().decode(
      FoodListPage.self, from: try JSONEncoder().encode(page))
    #expect(decoded == page)
  }

  @Test("A contextual list factory resolves to its query")
  func aContextualListFactoryResolvesToItsQuery() throws {
    let query = try FoodListQuery(dataTypes: [.branded])
    let request: FoodRequest<FoodListPage> = .foodList(query)
    #expect(request.resolution == .foodList(query))
  }

  @Test("An unannotated stored list request infers its page type")
  func anUnannotatedStoredListRequestInfersItsPageType() throws {
    let query = try FoodListQuery()
    let request = FoodRequest.foodList(query)
    let typed: FoodRequest<FoodListPage> = request
    #expect(typed.resolution == .foodList(query))
  }

  @Test("A consumer-defined list factory composes the library's query")
  func aConsumerDefinedListFactoryComposesTheLibrarysQuery() throws {
    let request = try FoodRequest.foundationFoods()
    guard case .foodList(let query) = request.resolution else {
      Issue.record("Expected a food list resolution, got \(request.resolution)")
      return
    }
    #expect(
      Endpoint.foodList(query).path == "/foods/list?dataType=Foundation&pageNumber=1&pageSize=200")
  }

  @Test("A consumer-defined response wraps a list endpoint")
  func aConsumerDefinedResponseWrapsAListEndpoint() throws {
    let endpoint = try #require(Endpoint<[FoodName]>(path: "/foods/list?pageSize=2"))
    let request = FoodRequest(endpoint: endpoint)
    #expect(request.resolution == .endpoint(endpoint))
    let names = try JSONDecoder().decode([FoodName].self, from: try Fixture.listBranded.data())
    #expect(names.count == 2)
  }

  private func decodeFoods(_ fixture: Fixture) throws -> [AbridgedFood] {
    try JSONDecoder().decode([AbridgedFood].self, from: try fixture.data())
  }
}
