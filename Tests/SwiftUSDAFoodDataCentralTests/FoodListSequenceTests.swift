import Foundation
import HTTPCore
import HTTPTesting
import HTTPTypes
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite("FoodData Central food list sequences", .timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodListSequenceTests {
  @Test("Creating sequences and iterators sends nothing")
  func creatingSequencesAndIteratorsSendsNothing() throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 2)
    let endpoint = try #require(Endpoint<FoodListPage>(path: "/foods/list?pageSize=2"))
    _ = client.foodListPages(query).makeAsyncIterator()
    _ = client.foods(listing: query).makeAsyncIterator()
    _ = client.pages(for: .foodList(query)).makeAsyncIterator()
    _ = client.items(for: .foodList(query)).makeAsyncIterator()
    _ = client.pages(for: FoodRequest(endpoint: endpoint)).makeAsyncIterator()
    _ = client.items(for: FoodRequest(endpoint: endpoint)).makeAsyncIterator()
    #expect(transport.requests.isEmpty)
  }

  @Test("Each read fetches one authenticated page and continues the query exactly")
  func eachReadFetchesOneAuthenticatedPageAndContinuesTheQueryExactly() async throws {
    let first = try Fixture.listFoundationPage1.data()
    let second = try Fixture.listFoundationPage2.data()
    let short = try JSONEncoder().encode(Array(try foods(.listFoundationPage1).prefix(1)))
    let transport = MockTransport(results: [
      .success(.ok(json: first)), .success(.ok(json: second)), .success(.ok(json: short)),
    ])
    let client = try makeClient(transport)
    let query = try FoodListQuery(
      dataTypes: [.foundation], pageSize: 2, sort: FoodSort(field: .fdcID, order: .descending))
    var pages = client.foodListPages(query).makeAsyncIterator()

    let one = try #require(try await pages.next())
    #expect(transport.requests.count == 1)
    #expect(one.pageNumber == 1)
    #expect(one.pageSize == 2)
    #expect(one.foods == (try foods(.listFoundationPage1)))
    let two = try #require(try await pages.next())
    #expect(transport.requests.count == 2)
    #expect(two.pageNumber == 2)
    #expect(two.foods.map(\.fdcID) == [2_257_045, 1_999_631])
    let three = try #require(try await pages.next())
    #expect(three.pageNumber == 3)
    #expect(three.foods.count == 1)
    #expect(try await pages.next() == nil)
    #expect(try await pages.next() == nil)

    let field = try #require(HTTPField.Name("X-Api-Key"))
    let paths = transport.requests.compactMap(\.request.path)
    #expect(
      paths
        == [1, 2, 3].map {
          "/fdc/v1/foods/list?dataType=Foundation&pageNumber=\($0)&pageSize=2"
            + "&sortBy=fdcId&sortOrder=desc"
        })
    for call in transport.requests {
      #expect(call.request.method == .get)
      #expect(call.request.authority == "api.nal.usda.gov")
      #expect(call.request.headerFields[field] == "private-test-key")
      #expect(call.request.path?.lowercased().contains("api_key") == false)
      #expect(call.body == .none)
    }
  }

  @Test("Continuation keeps several data types and a dotted sort name encoded on every page")
  func continuationKeepsSeveralDataTypesAndADottedSortNameEncodedOnEveryPage() async throws {
    let short = try JSONEncoder().encode(Array(try foods(.listFoundationPage1).prefix(1)))
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.listFoundationPage1.data())),
      .success(.ok(json: try Fixture.listFoundationPage2.data())),
      .success(.ok(json: short)),
    ])
    let client = try makeClient(transport)
    let query = try FoodListQuery(
      dataTypes: [.srLegacy, .survey], pageSize: 2,
      sort: FoodSort(field: .dataType, order: .ascending))
    var numbers: [Int] = []
    for try await page in client.foodListPages(query) {
      numbers.append(page.pageNumber)
    }
    #expect(numbers == [1, 2, 3])
    // Data types sort by raw value; a space is %20, parentheses are %28 and %29, and the comma
    // and the dot stay literal.
    #expect(
      transport.requests.compactMap(\.request.path)
        == [1, 2, 3].map {
          "/fdc/v1/foods/list?dataType=SR%20Legacy,Survey%20%28FNDDS%29&pageNumber=\($0)"
            + "&pageSize=2&sortBy=dataType.keyword&sortOrder=asc"
        })
  }

  @Test("An empty page after full pages is yielded and ends the list")
  func anEmptyPageAfterFullPagesIsYieldedAndEndsTheList() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.listFoundationPage1.data())),
      .success(.ok(json: Data("[]".utf8))),
    ])
    let client = try makeClient(transport)
    var pages = client.foodListPages(try FoodListQuery(dataTypes: [.foundation], pageSize: 2))
      .makeAsyncIterator()
    #expect(try await pages.next()?.foods.count == 2)
    let last = try #require(try await pages.next())
    #expect(last.foods.isEmpty)
    #expect(last.pageNumber == 2)
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 2)
  }

  @Test("Two iterators over one sequence traverse independently from the first page")
  func twoIteratorsOverOneSequenceTraverseIndependentlyFromTheFirstPage() async throws {
    let first = try Fixture.listFoundationPage1.data()
    let empty = Data("[]".utf8)
    let transport = MockTransport(results: [
      .success(.ok(json: first)), .success(.ok(json: first)), .success(.ok(json: empty)),
      .success(.ok(json: empty)),
    ])
    let client = try makeClient(transport)
    let pages = client.foodListPages(try FoodListQuery(dataTypes: [.foundation], pageSize: 2))
    var a = pages.makeAsyncIterator()
    var b = pages.makeAsyncIterator()
    #expect(try await a.next()?.pageNumber == 1)
    #expect(try await b.next()?.pageNumber == 1)
    #expect(try await a.next()?.pageNumber == 2)
    #expect(try await b.next()?.pageNumber == 2)
    #expect(try await a.next() == nil)
    #expect(try await b.next() == nil)
    let paths = transport.requests.compactMap(\.request.path)
    #expect(paths.filter { $0.contains("pageNumber=1&") }.count == 2)
    #expect(paths.filter { $0.contains("pageNumber=2&") }.count == 2)
  }

  @Test("Items are every food of every page in order")
  func itemsAreEveryFoodOfEveryPageInOrder() async throws {
    let bodies = [
      try Fixture.listFoundationPage1.data(), try Fixture.listFoundationPage2.data(),
      Data("[]".utf8),
    ]
    let pageTransport = MockTransport(results: bodies.map { .success(.ok(json: $0)) })
    let itemTransport = MockTransport(results: bodies.map { .success(.ok(json: $0)) })
    let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 2)
    var fromPages: [AbridgedFood] = []
    for try await page in try makeClient(pageTransport).foodListPages(query) {
      fromPages += page.foods
    }
    var items: [AbridgedFood] = []
    for try await food in try makeClient(itemTransport).foods(listing: query) {
      items.append(food)
    }
    #expect(items == fromPages)
    #expect(
      items.map(\.fdcID)
        == (try foods(.listFoundationPage1)).map(\.fdcID) + [2_257_045, 1_999_631])
    #expect(
      pageTransport.requests.map(\.request.path) == itemTransport.requests.map(\.request.path))
    #expect(itemTransport.requests.count == 3)
  }

  @Test("Request-based and query-based sequences send the same requests and yield the same values")
  func requestBasedAndQueryBasedSequencesSendTheSameRequestsAndYieldTheSameValues() async throws {
    let bodies = [try Fixture.listFoundationPage1.data(), Data("[]".utf8)]
    let transports = (0..<4).map { _ in
      MockTransport(results: bodies.map { .success(.ok(json: $0)) })
    }
    let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 2)
    let request: FoodRequest<FoodListPage> = .foodList(query)
    var queryPages: [FoodListPage] = []
    for try await page in try makeClient(transports[0]).foodListPages(query) {
      queryPages.append(page)
    }
    var requestPages: [FoodListPage] = []
    for try await page in try makeClient(transports[1]).pages(for: request) {
      requestPages.append(page)
    }
    var queryItems: [AbridgedFood] = []
    for try await food in try makeClient(transports[2]).foods(listing: query) {
      queryItems.append(food)
    }
    var requestItems: [AbridgedFood] = []
    for try await food in try makeClient(transports[3]).items(for: request) {
      requestItems.append(food)
    }
    #expect(queryPages == requestPages)
    #expect(queryItems == requestItems)
    #expect(queryPages.count == 2)
    let paths = transports.map { $0.requests.map(\.request.path) }
    #expect(paths.allSatisfy { $0 == paths[0] })
  }

  @Test("An endpoint request yields its one page and does not continue")
  func anEndpointRequestYieldsItsOnePageAndDoesNotContinue() async throws {
    let stored = FoodListPage(
      foods: try foods(.listFoundationPage1), pageNumber: 1, pageSize: 2)
    let transport = MockTransport(results: [.success(.ok(json: try JSONEncoder().encode(stored)))])
    let client = try makeClient(transport)
    let endpoint = try #require(Endpoint<FoodListPage>(path: "/stored/list-page"))
    var pages = client.pages(for: FoodRequest(endpoint: endpoint)).makeAsyncIterator()
    #expect(try await pages.next() == stored)
    #expect(try await pages.next() == nil)
    #expect(transport.requests.compactMap(\.request.path) == ["/fdc/v1/stored/list-page"])
  }

  @Test("Breaking out of items after the first food sends nothing more")
  func breakingOutOfItemsAfterTheFirstFoodSendsNothingMore() async throws {
    let first = try Fixture.listFoundationPage1.data()
    let transport = MockTransport(results: [.success(.ok(json: first)), .success(.ok(json: first))])
    let client = try makeClient(transport)
    for try await _ in client.foods(listing: try FoodListQuery(pageSize: 2)) {
      break
    }
    #expect(transport.requests.count == 1)
  }

  @Test("Cancellation before the first read sends nothing")
  func cancellationBeforeTheFirstReadSendsNothing() async throws {
    let transport = MockTransport()
    let client = try makeClient(transport)
    let query = try FoodListQuery(pageSize: 2)
    await withTaskGroup(of: Void.self) { group in
      group.cancelAll()
      group.addTask {
        var pages = client.foodListPages(query).makeAsyncIterator()
        var items = client.foods(listing: query).makeAsyncIterator()
        let pageError = await Self.failure(of: &pages)
        let itemError = await Self.failure(of: &items)
        #expect(Self.isCancellation(pageError))
        #expect(Self.isCancellation(itemError))
      }
    }
    #expect(transport.requests.isEmpty)
  }

  @Test("Cancellation between pages ends the page iterator without another request")
  func cancellationBetweenPagesEndsThePageIteratorWithoutAnotherRequest() async throws {
    let first = try Fixture.listFoundationPage1.data()
    let transport = MockTransport(results: [.success(.ok(json: first)), .success(.ok(json: first))])
    let client = try makeClient(transport)
    let query = try FoodListQuery(pageSize: 2)
    let entered = AsyncStream<Void>.makeStream()
    let resume = AsyncStream<Void>.makeStream()
    let task = Task { () async -> Bool in
      var pages = client.foodListPages(query).makeAsyncIterator()
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

  @Test("Cancellation between pages ends the item iterator without another request")
  func cancellationBetweenPagesEndsTheItemIteratorWithoutAnotherRequest() async throws {
    let first = try Fixture.listFoundationPage1.data()
    let transport = MockTransport(results: [.success(.ok(json: first)), .success(.ok(json: first))])
    let client = try makeClient(transport)
    let query = try FoodListQuery(pageSize: 2)
    let entered = AsyncStream<Void>.makeStream()
    let resume = AsyncStream<Void>.makeStream()
    let task = Task { () async -> Bool in
      var items = client.foods(listing: query).makeAsyncIterator()
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

  @Test("Item iteration observes cancellation while foods remain buffered")
  func itemIterationObservesCancellationWhileFoodsRemainBuffered() async throws {
    let first = try Fixture.listFoundationPage1.data()
    let transport = MockTransport(results: [.success(.ok(json: first))])
    let client = try makeClient(transport)
    let query = try FoodListQuery(pageSize: 2)
    let entered = AsyncStream<Void>.makeStream()
    let resume = AsyncStream<Void>.makeStream()
    let task = Task { () async -> Bool in
      var items = client.foods(listing: query).makeAsyncIterator()
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

  @Test("A failure on a later page ends the iterator")
  func aFailureOnALaterPageEndsTheIterator() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.listFoundationPage1.data())),
      .success(.text("unavailable", status: .serviceUnavailable)),
    ])
    let client = try makeClient(transport)
    var items = client.foods(listing: try FoodListQuery(pageSize: 2)).makeAsyncIterator()
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

  @Test("A page holding more foods than its size fails without being yielded")
  func aPageHoldingMoreFoodsThanItsSizeFailsWithoutBeingYielded() async throws {
    let three = try foods(.listFoundationPage1) + foods(.listFoundationPage2).prefix(1)
    let transport = MockTransport(results: [.success(.ok(json: try JSONEncoder().encode(three)))])
    let client = try makeClient(transport)
    var pages = client.foodListPages(try FoodListQuery(pageSize: 2)).makeAsyncIterator()
    let error = await Self.failure(of: &pages)
    #expect(Self.pagination(error) == .excessFoods(count: 3, pageSize: 2))
    #expect(try await pages.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("A full page at the largest page number fails without being yielded")
  func aFullPageAtTheLargestPageNumberFailsWithoutBeingYielded() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.listFoundationPage1.data()))
    ])
    let client = try makeClient(transport)
    var items = client.foods(listing: try FoodListQuery(pageNumber: .max, pageSize: 2))
      .makeAsyncIterator()
    let error = await Self.failure(of: &items)
    #expect(Self.pagination(error) == .pageNumberOverflow)
    #expect(try await items.next() == nil)
    #expect(transport.requests.count == 1)
  }

  @Test("The service's result window refusal ends both sequences with a pagination error")
  func theServicesResultWindowRefusalEndsBothSequencesWithAPaginationError() async throws {
    let refusal = Response.json(try Fixture.listBeyondEnd.data(), status: .badRequest)
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.listFoundationPage1.data())), .success(refusal),
      .success(refusal),
    ])
    let client = try makeClient(transport)
    let query = try FoodListQuery(dataTypes: [.foundation], pageNumber: 999, pageSize: 2)
    var pages = client.foodListPages(query).makeAsyncIterator()
    #expect(try await pages.next()?.pageNumber == 999)
    let pageError = await Self.failure(of: &pages)
    #expect(Self.pagination(pageError) == .resultWindowExceeded)
    #expect(try await pages.next() == nil)
    let deep = try FoodListQuery(dataTypes: [.foundation], pageNumber: 1_000, pageSize: 200)
    var items = client.foods(listing: deep).makeAsyncIterator()
    let itemError = await Self.failure(of: &items)
    #expect(Self.pagination(itemError) == .resultWindowExceeded)
    #expect(try await items.next() == nil)
    #expect(
      transport.requests.compactMap(\.request.path) == [
        "/fdc/v1/foods/list?dataType=Foundation&pageNumber=999&pageSize=2",
        "/fdc/v1/foods/list?dataType=Foundation&pageNumber=1000&pageSize=2",
        "/fdc/v1/foods/list?dataType=Foundation&pageNumber=1000&pageSize=200",
      ])
  }

  @Test("Recorded pages end at the result window just past one hundred thousand foods")
  func recordedPagesEndAtTheResultWindowJustPastOneHundredThousandFoods() async throws {
    let transport = MockTransport(results: [
      .success(.ok(json: try Fixture.listWindow50000.data())),
      .success(.json(try Fixture.listWindow50001.data(), status: .badRequest)),
    ])
    let client = try makeClient(transport)
    let query = try FoodListQuery(dataTypes: [.branded], pageNumber: 50_000, pageSize: 2)
    var pages = client.foodListPages(query).makeAsyncIterator()
    #expect(try await pages.next()?.foods.count == 2)
    let error = await Self.failure(of: &pages)
    #expect(Self.pagination(error) == .resultWindowExceeded)
    #expect(try await pages.next() == nil)
    #expect(
      transport.requests.compactMap(\.request.path) == [
        "/fdc/v1/foods/list?dataType=Branded&pageNumber=50000&pageSize=2",
        "/fdc/v1/foods/list?dataType=Branded&pageNumber=50001&pageSize=2",
      ])
  }

  @Test("Any other rejected page stays a transport failure", arguments: OtherRejection.allCases)
  func anyOtherRejectedPageStaysATransportFailure(_ rejection: OtherRejection) async throws {
    let transport = MockTransport(results: [.success(try rejection.response())])
    let client = try makeClient(transport)
    var pages = client.foodListPages(try FoodListQuery(pageSize: 2)).makeAsyncIterator()
    let error = await Self.failure(of: &pages)
    guard case .transport(.httpStatus(_, 400, _)) = error else {
      Issue.record("Expected a transport status failure, received \(String(describing: error)).")
      return
    }
    #expect(try await pages.next() == nil)
  }

  @Test("A single list page past the result window stays a transport failure")
  func aSingleListPagePastTheResultWindowStaysATransportFailure() async throws {
    let refusal = Response.json(try Fixture.listBeyondEnd.data(), status: .badRequest)
    let transport = MockTransport(results: [.success(refusal)])
    let client = try makeClient(transport)
    let query = try FoodListQuery(dataTypes: [.foundation], pageNumber: 1_000, pageSize: 200)
    do throws(FoodDataCentralError) {
      _ = try await client.value(for: .foodList(query))
      Issue.record("A refused page must fail.")
    } catch {
      guard case .transport(.httpStatus(_, 400, _)) = error else {
        Issue.record("Expected a transport status failure, received \(error).")
        return
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

  private func foods(_ fixture: Fixture) throws -> [AbridgedFood] {
    try JSONDecoder().decode([AbridgedFood].self, from: fixture.data())
  }

  private func makeClient(
    _ transport: MockTransport
  ) throws(FoodDataCentralError) -> FoodDataCentralClient {
    FoodDataCentralClient(
      configuration: try FoodDataCentralConfiguration(apiKey: "private-test-key"),
      transport: transport)
  }

  private static func failure(
    of pages: inout FoodListPageSequence.Iterator
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
    of items: inout FoodListItemSequence.Iterator
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
