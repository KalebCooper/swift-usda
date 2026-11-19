# Changelog

All notable changes are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- `SwiftUSDAFoodDataCentralModels`, a product with no networking dependency: `Endpoint`, the
  `FoodRequest` request type with its public `resolution`, and
  `Endpoint.food(_:nutrients:)` and `Endpoint.abridgedFood(_:nutrients:)` for
  `GET /food/{fdcId}` in the full and abridged formats.
- `Endpoint.init?(path:)` and `Endpoint.init?(link:)`, which build an endpoint from a relative path
  or a FoodData Central link and return `nil` for an `api_key` query parameter in any spelling, a
  foreign origin, or a malformed path.
- Full-format records as the `Food` enum, decoded by data type into `BrandedFood`,
  `FoundationFood`, `SRLegacyFood`, and `SurveyFood`, with any other data type kept whole as
  `.other(dataType:_:)`. Abridged records as `AbridgedFood`.
- Public memberwise initializers on every response model. `ndbNumber` and `FoodAttribute.value`
  decode from a JSON integer or string into one string.
- Validated inputs `FoodID`, `NutrientNumber`, and `NutrientNumbers` (one to 25 distinct nutrients),
  the open `FoodDataType`, and `FoodDataCentralValidationError`.
- `DataGovErrorResponse` for api.data.gov gateway error bodies, and `JSONValue` for records kept
  whole.
- `SwiftUSDAFoodDataCentral`, a product with `FoodDataCentralClient`, which offers `food(_:nutrients:)`,
  `abridgedFood(_:nutrients:)`, `value(for:)`, and `send(_:)`, sends the API key in the `X-Api-Key`
  header, checks cancellation before every request, and never follows redirects. It is created with
  `init(apiKey:)` or `init(configuration:session:)` on Apple platforms, or with the
  `init(configuration:transport:)` transport initializer on any platform.
- `FoodDataCentralConfiguration` with a required API key, whose `description` redacts the key, and
  the typed `FoodDataCentralError` with `gateway`, `invalidAPIKey`, `pagination`, and `transport`
  cases.
- Multiple-food lookup for `GET /foods`: `FoodIDs` (one to 20 distinct identifiers),
  `Endpoint.foods(_:nutrients:)` and `Endpoint.abridgedFoods(_:nutrients:)`,
  `FoodRequest.foods(_:nutrients:)` and `FoodRequest.abridgedFoods(_:nutrients:)`, and the client
  methods `foods(_:nutrients:)` and `abridgedFoods(_:nutrients:)`. Unknown identifiers are
  omitted; the service's result order is undocumented and need not match the request.
- `FoodDataCentralValidationError.duplicateFoodID` and `.foodIDCount`.
- `FoodRequest.Resolution` cases `foodList(FoodListQuery)` and `foodSearch(FoodSearchQuery)`, and a
  `value(for:)` overload for `FoodRequest<FoodListPage>`.
- Food lists for `GET /foods/list`: `FoodListQuery` (data types, a one-based page number, a page size
  of 1 to 200, and an optional `FoodSort`), `FoodSort`, `FoodSortField`, `FoodSortOrder`,
  `FoodListPage`, `Endpoint.foodList(_:)`, and `FoodRequest.foodList(_:)`. `FoodSortField` is open;
  only `fdcId` is confirmed by a recorded response, and the specification warns that
  `dataType.keyword` and `lowercaseDescription.keyword` will change.
- Lazy list reads: `FoodDataCentralClient.foodListPages(_:)` and `foods(listing:)`, and for a list
  request `pages(for:)` and `items(for:)`, returning `FoodListPageSequence` and
  `FoodListItemSequence`. Each read fetches one page. The list ends at the first page shorter than
  the page size, which is the SDK's reading of the response and not a service guarantee; a list
  whose length is a multiple of the page size ends with one empty page. Pages are not a snapshot.
- `FoodListQuery.next(after:)` and `FoodPaginationError`, which report both food list and food
  search failures: a page that does not answer its query, a page holding more foods than its size, a page number that overflows, and a
  page past FoodData Central's undocumented result window (on the food list, a page number times
  page size above 100,000). The sequences recognize the window from the service's exact response text;
  single-page calls report it as `FoodDataCentralError.transport`.
- `FoodDataType.experimental`, a data type the service accepts as a filter but its specification
  omits.
- `FoodDataCentralValidationError.pageNumber` and `.pageSize`.
- Food search for `POST /foods/search`: `FoodSearchQuery` (search terms that may use FoodData
  Central's search operators, data types, a brand owner sent exactly as given that applies only to
  Branded foods, an optional `FoodSort`, a one-based page number, and a page size of 1 to 200),
  `Endpoint.foodSearch(_:)`, and `FoodRequest.foodSearch(_:)`. Every parameter travels in a JSON body
  encoded with sorted keys. Pages are numbered from 1, as recorded for search. Empty or
  whitespace-only terms are rejected before sending, although the service answers them with every
  food.
- `TradeChannel` and `FoodPublicationDate` for the trade channel filter (up to three) and the
  publication date range, which the service accepts only in a `POST` body and applies, as recorded.
- `FoodSearchResult`, `FoodSearchCriteria`, `SearchResultFood`, and `SearchResultFoodNutrient`,
  checked against recorded search responses. `SearchResultFood` carries `brandName`,
  `foodCategory`, `householdServingFullText`, `servingSize`, `servingSizeUnit`, and
  `tradeChannels`, and `FoodSearchCriteria` carries `requireAllWords`. Nutrients decode from `value`, `nutrientName`, `nutrientNumber`, and
  `nutrientId` or from `amount`, `name`, and `number`, and a food's publication date from
  `publishedDate` or `publicationDate`, the first spelling of each preferred; encoding writes the
  first spelling. A malformed `foodSearchCriteria` echo decodes as `nil` and never fails the page.
- `FoodSearchQuery.next(after:)`, which continues while `currentPage` is below `totalPages` and
  reports a page that does not answer its query, holds more foods than its size, or reports
  contradictory totals.
- Lazy search reads: `FoodDataCentralClient.foodSearchPages(_:)` and `foods(matching:)`, and for a
  search request `pages(for:)` and `items(for:)`, returning `FoodSearchPageSequence` and
  `FoodSearchItemSequence`. No search result window refusal has been observed; the sequences
  recognize the food list's refusal text as `FoodPaginationError.resultWindowExceeded` in case
  search sends it. A start page past the last fails with
  `FoodPaginationError.unexpectedPageNumber(actual:expected:)`, because the service answers it as
  page 1.
- `Endpoint.decode(_:)`, which decodes a response body the way the SDK does, for consumers using
  their own networking stack.
- `EndpointMethod`, with `Endpoint.method` and `Endpoint.body` for endpoints that post a JSON body.
- `FoodDataCentralValidationError.emptySearchQuery`, `.publicationDate(year:month:day:)`,
  `.publicationDateRange(start:end:)`, and `.tradeChannelCount(_:)`.
- An `HTTPPortable` trait for Linux and Android transports.
- DocC documentation for both products, including articles on paging food lists and searching
  foods.
- A SwiftUI demo app, `Examples/SwiftUSDAFoodDataCentralDemo`, that searches foods, loads more
  results a page at a time, and shows the full record for a food.

### Fixed

- A multiple-food lookup that matches no known identifier returns an empty array. The service
  answers it with `{}` rather than `[]`, which previously failed to decode. Endpoints from
  `Endpoint.foods(_:nutrients:)` and `Endpoint.abridgedFoods(_:nutrients:)` now compare unequal to
  endpoints created from the same path, because only they decode `{}` as no foods.
