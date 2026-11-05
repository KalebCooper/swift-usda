import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

// No search response has been recorded, so these bodies are literals in the shape of the
// FoodData Central specification, version 1.0.1.
@Suite("FoodData Central food search sequences", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodSearchSequenceTests {
  @Test("Creating search sequences and iterators sends nothing")
  func creatingSearchSequencesAndIteratorsSendsNothing() throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("apple", pageSize: 2)
    let endpoint = try #require(Endpoint<FoodSearchResult>(path: "/stored/search-page"))
    _ = client.foodSearchPages(query).makeAsyncIterator()
    _ = client.foods(matching: query).makeAsyncIterator()
    _ = client.pages(for: .foodSearch(query)).makeAsyncIterator()
    _ = client.items(for: .foodSearch(query)).makeAsyncIterator()
    _ = client.pages(for: FoodRequest(endpoint: endpoint)).makeAsyncIterator()
    _ = client.items(for: FoodRequest(endpoint: endpoint)).makeAsyncIterator()
    #expect(transport.requests.isEmpty)
  }

  @Test("Search call sites infer their sequence types from the query and the request")
  func searchCallSitesInferTheirSequenceTypesFromTheQueryAndTheRequest() throws {
    let client = try makeClient(MockTransport())
    let query = try FoodSearchQuery("apple")
    let stored = FoodRequest.foodSearch(query)
    let pages: FoodSearchPageSequence = client.foodSearchPages(query)
    let foods: FoodSearchItemSequence = client.foods(matching: query)
    let requestPages: FoodSearchPageSequence = client.pages(for: stored)
    let requestFoods: FoodSearchItemSequence = client.items(for: .foodSearch(query))
    let listFoods: FoodListItemSequence = client.foods(listing: try FoodListQuery())
    _ = (pages, foods, requestPages, requestFoods, listFoods)
  }

  @Test("Each read posts one authenticated page and continues the query exactly")
  func eachReadPostsOneAuthenticatedPageAndContinuesTheQueryExactly() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(1, of: 3, hits: 5, ids: [1, 2]))),
      .success(.ok(json: Self.page(2, of: 3, hits: 5, ids: [3, 4]))),
      .success(.ok(json: Self.page(3, of: 3, hits: 5, ids: [5]))),
    ])
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("apple", pageSize: 2)
    var pages = client.foodSearchPages(query).makeAsyncIterator()

    let one = try #require(try await pages.next())
    #expect(transport.requests.count == 1)
    #expect(one.currentPage == 1)
    #expect(one.totalHits == 5)
    #expect(one.foods.map(\.fdcID) == [1, 2])
    let two = try #require(try await pages.next())
    #expect(transport.requests.count == 2)
    #expect(two.foods.map(\.fdcID) == [3, 4])
    let three = try #require(try await pages.next())
    #expect(three.foods.map(\.fdcID) == [5])
    #expect(try await pages.next() == nil)
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 3)

    let field = try #require(HTTPField.Name("X-Api-Key"))
    let expected: [TransportBody] = [1, 2, 3].map { number in
      .bytes(Data(#"{"pageNumber":\#(number),"pageSize":2,"query":"apple"}"#.utf8))
    }
    #expect(transport.requests.map(\.body) == expected)
    for call in transport.requests {
      #expect(call.request.method == .post)
      #expect(call.request.authority == "api.nal.usda.gov")
      #expect(call.request.path == "/fdc/v1/foods/search")
      #expect(call.request.headerFields[.contentType] == "application/json")
      #expect(call.request.headerFields[field] == "private-test-key")
      #expect(call.request.path?.lowercased().contains("api_key") == false)
    }
  }

  @Test("Continuation keeps every filter and the sort in the body of every page")
  func continuationKeepsEveryFilterAndTheSortInTheBodyOfEveryPage() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(4, of: 5, hits: 9, ids: [1, 2]))),
      .success(.ok(json: Self.page(5, of: 5, hits: 9, ids: [3]))),
    ])
    let client = try makeClient(transport)
    let query = try FoodSearchQuery(
      "cheddar/swiss \"aged\"", brandOwner: "Kraft Heinz", dataTypes: [.survey, .branded],
      endDate: FoodPublicationDate(year: 2021, month: 12, day: 30), pageNumber: 4, pageSize: 2,
      sort: FoodSort(field: .publishedDate, order: .descending),
      startDate: FoodPublicationDate(year: 2021, month: 1, day: 1),
      tradeChannels: [.grocery, .foodService])
    var numbers: [Int] = []
    for try await page in client.foodSearchPages(query) {
      numbers.append(page.currentPage)
    }
    #expect(numbers == [4, 5])
    let expected: [TransportBody] = [4, 5].map { (number: Int) -> TransportBody in
      let json: String =
        #"{"brandOwner":"Kraft Heinz","dataType":["Branded","Survey (FNDDS)"],"#
        + #""endDate":"2021-12-30","pageNumber":\#(number),"pageSize":2,"#
        + #""query":"cheddar/swiss \"aged\"","sortBy":"publishedDate","sortOrder":"desc","#
        + #""startDate":"2021-01-01","tradeChannel":["FOOD_SERVICE","GROCERY"]}"#
      return .bytes(Data(json.utf8))
    }
    #expect(transport.requests.map(\.body) == expected)
  }

  @Test("A search that matches nothing yields one empty page and ends")
  func aSearchThatMatchesNothingYieldsOneEmptyPageAndEnds() async throws {
    let empty = Self.page(1, of: 0, hits: 0, ids: [])
    let transport = MockTransport(results: [
      .success(.ok(json: empty)), .success(.ok(json: empty)),
    ])
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("zzzz", pageSize: 2)
    var pages = client.foodSearchPages(query).makeAsyncIterator()
    let only = try #require(try await pages.next())
    #expect(only.foods.isEmpty)
    #expect(only.totalHits == 0)
    #expect(try await pages.next() == nil)
    var items = client.foods(matching: query).makeAsyncIterator()
    #expect(try await items.next() == nil)
    #expect(try await items.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("Two search iterators over one sequence traverse independently from the first page")
  func twoSearchIteratorsOverOneSequenceTraverseIndependentlyFromTheFirstPage() async throws {
    let first = Self.page(1, of: 2, hits: 3, ids: [1, 2])
    let last = Self.page(2, of: 2, hits: 3, ids: [3])
    let transport = MockTransport(results: [
      .success(.ok(json: first)), .success(.ok(json: first)), .success(.ok(json: last)),
      .success(.ok(json: last)),
    ])
    let client = try makeClient(transport)
    let pages = client.foodSearchPages(try FoodSearchQuery("apple", pageSize: 2))
    var a = pages.makeAsyncIterator()
    var b = pages.makeAsyncIterator()
    #expect(try await a.next()?.currentPage == 1)
    #expect(try await b.next()?.currentPage == 1)
    #expect(try await a.next()?.currentPage == 2)
    #expect(try await b.next()?.currentPage == 2)
    #expect(try await a.next() == nil)
    #expect(try await b.next() == nil)
    let bodies = transport.requests.map(\.body)
    let pageOne = TransportBody.bytes(Data(#"{"pageNumber":1,"pageSize":2,"query":"apple"}"#.utf8))
    let pageTwo = TransportBody.bytes(Data(#"{"pageNumber":2,"pageSize":2,"query":"apple"}"#.utf8))
    #expect(bodies == [pageOne, pageOne, pageTwo, pageTwo])
  }

  @Test("Search items are every food of every page in order")
  func searchItemsAreEveryFoodOfEveryPageInOrder() async throws {
    let bodies = [
      Self.page(1, of: 3, hits: 5, ids: [1, 2]), Self.page(2, of: 3, hits: 5, ids: [3, 4]),
      Self.page(3, of: 3, hits: 5, ids: [5]),
    ]
    let pageTransport = MockTransport(results: bodies.map { .success(.ok(json: $0)) })
    let itemTransport = MockTransport(results: bodies.map { .success(.ok(json: $0)) })
    let query = try FoodSearchQuery("apple", pageSize: 2)
    var fromPages: [SearchResultFood] = []
    for try await page in try makeClient(pageTransport).foodSearchPages(query) {
      fromPages += page.foods
    }
    var items: [SearchResultFood] = []
    for try await food in try makeClient(itemTransport).foods(matching: query) {
      items.append(food)
    }
    #expect(items == fromPages)
    #expect(items.map(\.fdcID) == [1, 2, 3, 4, 5])
    #expect(pageTransport.requests.map(\.body) == itemTransport.requests.map(\.body))
    #expect(itemTransport.requests.count == 3)
  }

  @Test("Request-based and query-based search sequences send the same requests and values")
  func requestBasedAndQueryBasedSearchSequencesSendTheSameRequestsAndValues() async throws {
    let bodies = [
      Self.page(1, of: 2, hits: 3, ids: [1, 2]), Self.page(2, of: 2, hits: 3, ids: [3]),
    ]
    let transports = (0..<4).map { _ in
      MockTransport(results: bodies.map { .success(.ok(json: $0)) })
    }
    let query = try FoodSearchQuery("apple", pageSize: 2)
    let request: FoodRequest<FoodSearchResult> = .foodSearch(query)
    var queryPages: [FoodSearchResult] = []
    for try await page in try makeClient(transports[0]).foodSearchPages(query) {
      queryPages.append(page)
    }
    var requestPages: [FoodSearchResult] = []
    for try await page in try makeClient(transports[1]).pages(for: request) {
      requestPages.append(page)
    }
    var queryItems: [SearchResultFood] = []
    for try await food in try makeClient(transports[2]).foods(matching: query) {
      queryItems.append(food)
    }
    var requestItems: [SearchResultFood] = []
    for try await food in try makeClient(transports[3]).items(for: request) {
      requestItems.append(food)
    }
    #expect(queryPages == requestPages)
    #expect(queryItems == requestItems)
    #expect(queryPages.count == 2)
    let sent = transports.map { $0.requests.map(\.body) }
    #expect(sent.allSatisfy { $0 == sent[0] })
  }

  @Test("A search endpoint request yields its one page and does not continue")
  func aSearchEndpointRequestYieldsItsOnePageAndDoesNotContinue() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(1, of: 3, hits: 5, ids: [1, 2])))
    ])
    let client = try makeClient(transport)
    let endpoint = try #require(Endpoint<FoodSearchResult>(path: "/stored/search-page"))
    var pages = client.pages(for: FoodRequest(endpoint: endpoint)).makeAsyncIterator()
    let page = try #require(try await pages.next())
    #expect(page.foods.map(\.fdcID) == [1, 2])
    #expect(page.totalPages == 3)
    #expect(try await pages.next() == nil)
    #expect(transport.requests.compactMap(\.request.path) == ["/fdc/v1/stored/search-page"])
    #expect(transport.requests.first?.request.method == .get)
  }

  @Test("Breaking out of search items after the first food sends nothing more")
  func breakingOutOfSearchItemsAfterTheFirstFoodSendsNothingMore() async throws {
    let first = Self.page(1, of: 2, hits: 3, ids: [1, 2])
    let transport = MockTransport(results: [.success(.ok(json: first)), .success(.ok(json: first))])
    let client = try makeClient(transport)
    for try await _ in client.foods(matching: try FoodSearchQuery("apple", pageSize: 2)) {
      break
    }
    #expect(transport.requests.count == 1)
  }

  @Test("Cancellation before the first search read sends nothing")
  func cancellationBeforeTheFirstSearchReadSendsNothing() async throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("apple", pageSize: 2)
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        var pages = client.foodSearchPages(query).makeAsyncIterator()
        var items = client.foods(matching: query).makeAsyncIterator()
        let pageError = await Self.failure(of: &pages)
        let itemError = await Self.failure(of: &items)
        #expect(Self.isCancellation(pageError))
        #expect(Self.isCancellation(itemError))
      }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("Cancellation between search pages ends the page iterator without another request")
  func cancellationBetweenSearchPagesEndsThePageIteratorWithoutAnotherRequest() async throws {
    let first = Self.page(1, of: 2, hits: 3, ids: [1, 2])
    let transport = MockTransport(results: [.success(.ok(json: first)), .success(.ok(json: first))])
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("apple", pageSize: 2)
    let entered = AsyncStream<Void>.makeStream()
    let resume = AsyncStream<Void>.makeStream()
    let task = Task { () async -> Bool in
      var pages = client.foodSearchPages(query).makeAsyncIterator()
      guard (try? await pages.next()) != nil else { return false }
      entered.continuation.yield(())
      var gate = resume.stream.makeAsyncIterator()
      _ = await gate.next()
      guard Self.isCancellation(await Self.failure(of: &pages)) else { return false }
      return (try? await pages.next()) == .some(nil)
    }
    var gate = entered.stream.makeAsyncIterator()
    _ = await gate.next()
    task.cancel()
    resume.continuation.finish()
    entered.continuation.finish()
    #expect(await task.value)
    #expect(transport.requests.count == 1)
  }

  @Test("Cancellation between search pages ends the item iterator without another request")
  func cancellationBetweenSearchPagesEndsTheItemIteratorWithoutAnotherRequest() async throws {
    let first = Self.page(1, of: 2, hits: 3, ids: [1, 2])
    let transport = MockTransport(results: [.success(.ok(json: first)), .success(.ok(json: first))])
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("apple", pageSize: 2)
    let entered = AsyncStream<Void>.makeStream()
    let resume = AsyncStream<Void>.makeStream()
    let task = Task { () async -> Bool in
      var items = client.foods(matching: query).makeAsyncIterator()
      guard (try? await items.next()) != nil, (try? await items.next()) != nil else { return false }
      entered.continuation.yield(())
      var gate = resume.stream.makeAsyncIterator()
      _ = await gate.next()
      guard Self.isCancellation(await Self.failure(of: &items)) else { return false }
      return (try? await items.next()) == .some(nil)
    }
    var gate = entered.stream.makeAsyncIterator()
    _ = await gate.next()
    task.cancel()
    resume.continuation.finish()
    entered.continuation.finish()
    #expect(await task.value)
    #expect(transport.requests.count == 1)
  }

  @Test("Search item iteration observes cancellation while foods remain buffered")
  func searchItemIterationObservesCancellationWhileFoodsRemainBuffered() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(1, of: 2, hits: 3, ids: [1, 2])))
    ])
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("apple", pageSize: 2)
    let entered = AsyncStream<Void>.makeStream()
    let resume = AsyncStream<Void>.makeStream()
    let task = Task { () async -> Bool in
      var items = client.foods(matching: query).makeAsyncIterator()
      guard (try? await items.next()) != nil else { return false }
      entered.continuation.yield(())
      var gate = resume.stream.makeAsyncIterator()
      _ = await gate.next()
      guard Self.isCancellation(await Self.failure(of: &items)) else { return false }
      return (try? await items.next()) == .some(nil)
    }
    var gate = entered.stream.makeAsyncIterator()
    _ = await gate.next()
    task.cancel()
    resume.continuation.finish()
    entered.continuation.finish()
    #expect(await task.value)
    #expect(transport.requests.count == 1)
  }

  @Test("A failure on a later search page ends the iterator")
  func aFailureOnALaterSearchPageEndsTheIterator() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(1, of: 2, hits: 3, ids: [1, 2]))),
      .success(.text("unavailable", status: .serviceUnavailable)),
    ])
    let client = try makeClient(transport)
    var items = client.foods(matching: try FoodSearchQuery("apple", pageSize: 2))
      .makeAsyncIterator()
    #expect(try await items.next() != nil)
    #expect(try await items.next() != nil)
    let error = await Self.failure(of: &items)
    guard case .transport(.httpStatus(_, 503, _)) = error else {
      Issue.record(
        "Expected the later page's status failure, received \(String(describing: error)).")
      return
    }
    #expect(try await items.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test(
    "A search page that cannot be continued fails without being yielded",
    arguments: UncontinuablePage.allCases)
  func aSearchPageThatCannotBeContinuedFailsWithoutBeingYielded(
    _ uncontinuable: UncontinuablePage
  ) async throws {
    let transport = MockTransport(results: [.success(.ok(json: uncontinuable.body))])
    let client = try makeClient(transport)
    var pages = client.foodSearchPages(try FoodSearchQuery("apple", pageSize: 2))
      .makeAsyncIterator()
    let error = await Self.failure(of: &pages)
    #expect(Self.pagination(error) == uncontinuable.error)
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("A search page that repeats the previous page fails without being yielded")
  func aSearchPageThatRepeatsThePreviousPageFailsWithoutBeingYielded() async throws {
    let first = Self.page(1, of: 3, hits: 5, ids: [1, 2])
    let transport = MockTransport(results: [.success(.ok(json: first)), .success(.ok(json: first))])
    let client = try makeClient(transport)
    var items = client.foods(matching: try FoodSearchQuery("apple", pageSize: 2))
      .makeAsyncIterator()
    #expect(try await items.next()?.fdcID == 1)
    #expect(try await items.next()?.fdcID == 2)
    let error = await Self.failure(of: &items)
    #expect(Self.pagination(error) == .unexpectedPageNumber(actual: 1, expected: 2))
    #expect(try await items.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("Totals that stop progressing mid-search fail without yielding the page")
  func totalsThatStopProgressingMidSearchFailWithoutYieldingThePage() async throws {
    // The second page still reports hits but no pages, so the totals contradict each other.
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(1, of: 3, hits: 5, ids: [1, 2]))),
      .success(.ok(json: Self.page(2, of: 0, hits: 5, ids: [3, 4]))),
    ])
    let client = try makeClient(transport)
    var pages = client.foodSearchPages(try FoodSearchQuery("apple", pageSize: 2))
      .makeAsyncIterator()
    #expect(try await pages.next()?.currentPage == 1)
    let error = await Self.failure(of: &pages)
    #expect(Self.pagination(error) == .inconsistentTotals(totalHits: 5, totalPages: 0))
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("A search request with a later starting page sends that page first")
  func aSearchRequestWithALaterStartingPageSendsThatPageFirst() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(3, of: 4, hits: 7, ids: [5, 6]))),
      .success(.ok(json: Self.page(4, of: 4, hits: 7, ids: [7]))),
    ])
    let client = try makeClient(transport)
    let request: FoodRequest<FoodSearchResult> = .foodSearch(
      try FoodSearchQuery("apple", pageNumber: 3, pageSize: 2))
    var numbers: [Int] = []
    for try await page in client.pages(for: request) {
      numbers.append(page.currentPage)
    }
    #expect(numbers == [3, 4])
    let expected: [TransportBody] = [3, 4].map { number in
      .bytes(Data(#"{"pageNumber":\#(number),"pageSize":2,"query":"apple"}"#.utf8))
    }
    #expect(transport.requests.map(\.body) == expected)
  }

  @Test("A page count that shrinks below the current page ends the search after that page")
  func aPageCountThatShrinksBelowTheCurrentPageEndsTheSearchAfterThatPage() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(1, of: 3, hits: 5, ids: [1, 2]))),
      .success(.ok(json: Self.page(2, of: 1, hits: 2, ids: [3, 4]))),
    ])
    let client = try makeClient(transport)
    var pages = client.foodSearchPages(try FoodSearchQuery("apple", pageSize: 2))
      .makeAsyncIterator()
    #expect(try await pages.next()?.currentPage == 1)
    let last = try #require(try await pages.next())
    #expect(last.currentPage == 2)
    #expect(last.totalPages == 1)
    #expect(last.foods.map(\.fdcID) == [3, 4])
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 2)
  }

  // The refusal body is the one observed on the food list; no search refusal has been recorded,
  // so the same body is assumed for search.
  @Test("The service's result window refusal ends both search sequences with a pagination error")
  func theServicesResultWindowRefusalEndsBothSearchSequencesWithAPaginationError() async throws {
    let refusal = Response.json(try Fixture.listBeyondEnd.data(), status: .badRequest)
    let transport = MockTransport(results: [
      .success(.ok(json: Self.page(999, of: 2_000, hits: 3_999, ids: [1, 2]))),
      .success(refusal), .success(refusal),
    ])
    let client = try makeClient(transport)
    var pages = client.foodSearchPages(try FoodSearchQuery("apple", pageNumber: 999, pageSize: 2))
      .makeAsyncIterator()
    #expect(try await pages.next()?.currentPage == 999)
    let pageError = await Self.failure(of: &pages)
    #expect(Self.pagination(pageError) == .resultWindowExceeded)
    #expect(try await pages.next() == nil)
    let deep = try FoodSearchQuery("apple", pageNumber: 1_000, pageSize: 200)
    var items = client.foods(matching: deep).makeAsyncIterator()
    let itemError = await Self.failure(of: &items)
    #expect(Self.pagination(itemError) == .resultWindowExceeded)
    #expect(try await items.next() == nil)
    #expect(transport.requests.count == 3)
  }

  @Test(
    "Any other rejected search page stays a transport failure",
    arguments: OtherRejection.allCases)
  func anyOtherRejectedSearchPageStaysATransportFailure(_ rejection: OtherRejection) async throws {
    let transport = MockTransport(results: [.success(try rejection.response())])
    let client = try makeClient(transport)
    var pages = client.foodSearchPages(try FoodSearchQuery("apple", pageSize: 2))
      .makeAsyncIterator()
    let error = await Self.failure(of: &pages)
    guard case .transport(.httpStatus(_, 400, _)) = error else {
      Issue.record("Expected a transport status failure, received \(String(describing: error)).")
      return
    }
    #expect(try await pages.next() == nil)
  }

  @Test("A single search page past the result window stays a transport failure")
  func aSingleSearchPagePastTheResultWindowStaysATransportFailure() async throws {
    let refusal = Response.json(try Fixture.listBeyondEnd.data(), status: .badRequest)
    let transport = MockTransport(results: [.success(refusal)])
    let client = try makeClient(transport)
    let query = try FoodSearchQuery("apple", pageNumber: 1_000, pageSize: 200)
    do throws(FoodDataCentralError) {
      _ = try await client.value(for: .foodSearch(query))
      Issue.record("A refused page must fail.")
    } catch {
      guard case .transport(.httpStatus(_, 400, _)) = error else {
        Issue.record("Expected a transport status failure, received \(error).")
        return
      }
    }
  }

  enum UncontinuablePage: CaseIterable {
    case excessFoods
    case hitsWithoutPages
    case otherPageNumber

    var body: Data {
      switch self {
      case .excessFoods: page(1, of: 2, hits: 4, ids: [1, 2, 3])
      case .hitsWithoutPages: page(1, of: 0, hits: 2, ids: [1, 2])
      case .otherPageNumber: page(2, of: 3, hits: 5, ids: [1, 2])
      }
    }

    var error: FoodPaginationError {
      switch self {
      case .excessFoods: .excessFoods(count: 3, pageSize: 2)
      case .hitsWithoutPages: .inconsistentTotals(totalHits: 2, totalPages: 0)
      case .otherPageNumber: .unexpectedPageNumber(actual: 2, expected: 1)
      }
    }
  }

  enum OtherRejection: CaseIterable {
    case jsonBody
    case trailingNewline

    func response() throws -> Response {
      switch self {
      case .jsonBody:
        return .json(try Fixture.listSortDescription.data(), status: .badRequest)
      case .trailingNewline:
        return .json(try Fixture.listBeyondEnd.data() + Data("\n".utf8), status: .badRequest)
      }
    }
  }

  // A search page body with the specification's envelope and minimal foods.
  static func page(_ current: Int, of total: Int, hits: Int, ids: [Int]) -> Data {
    let foods = ids.map { #"{"fdcId":\#($0),"description":"Food \#($0)","dataType":"Branded"}"# }
    return Data(
      (#"{"totalHits":\#(hits),"currentPage":\#(current),"totalPages":\#(total),"#
        + #""foods":[\#(foods.joined(separator: ","))]}"#).utf8)
  }

  private func makeClient(
    _ transport: MockTransport
  ) throws(FoodDataCentralError) -> FoodDataCentralClient {
    FoodDataCentralClient(
      configuration: try FoodDataCentralConfiguration(apiKey: "private-test-key"),
      transport: transport)
  }

  private static func failure(
    of pages: inout FoodSearchPageSequence.Iterator
  ) async -> FoodDataCentralError? {
    do throws(FoodDataCentralError) {
      let page = try await pages.next()
      Issue.record("Expected a failure, received \(String(describing: page)).")
      return nil
    } catch {
      return error
    }
  }

  private static func failure(
    of items: inout FoodSearchItemSequence.Iterator
  ) async -> FoodDataCentralError? {
    do throws(FoodDataCentralError) {
      let food = try await items.next()
      Issue.record("Expected a failure, received \(String(describing: food)).")
      return nil
    } catch {
      return error
    }
  }

  private static func isCancellation(_ error: FoodDataCentralError?) -> Bool {
    guard case .transport(.cancelled) = error else { return false }
    return true
  }

  private static func pagination(_ error: FoodDataCentralError?) -> FoodPaginationError? {
    guard case .pagination(let failure) = error else { return nil }
    return failure
  }
}
