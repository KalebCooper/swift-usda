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
  header, and checks cancellation before every request.
- `FoodDataCentralConfiguration` with a required API key, and the typed `FoodDataCentralError` with
  `gateway`, `invalidAPIKey`, and `transport` cases.
- Multiple-food lookup for `GET /foods`: `FoodIDs` (one to 20 distinct identifiers),
  `Endpoint.foods(_:nutrients:)` and `Endpoint.abridgedFoods(_:nutrients:)`,
  `FoodRequest.foods(_:nutrients:)` and `FoodRequest.abridgedFoods(_:nutrients:)`, and the client
  methods `foods(_:nutrients:)` and `abridgedFoods(_:nutrients:)`. The specification says unknown
  identifiers are omitted; the service's result order is undocumented.
- `FoodDataCentralValidationError.duplicateFoodID` and `.foodIDCount`.
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
- `FoodListQuery.next(after:)` and `FoodListPaginationError`, which report a page that does not
  answer its query, a page holding more foods than its size, a page number that overflows, and a
  page past FoodData Central's undocumented result window (observed at a page number times page
  size of 200,000). The sequences recognize the window from the service's exact response text;
  single-page calls report it as `FoodDataCentralError.transport`.
- `FoodDataType.experimental`, a data type the service accepts as a filter but its specification
  omits.
- `FoodDataCentralValidationError.pageNumber` and `.pageSize`.
- An `HTTPPortable` trait for Linux and Android transports.
- DocC documentation for both products, including an article on paging food lists.

### Changed

- `FoodDataCentralError` has a new case, `pagination(FoodListPaginationError)`, and
  `FoodRequest.Resolution` has a new case, `foodList(FoodListQuery)`. Both are public enums, so an
  exhaustive `switch` over either needs a new case. `FoodDataCentralValidationError` also gains two
  cases.
- `FoodDataCentralClient` has a second `value(for:)` overload for `FoodRequest<FoodListPage>`. Calls
  with a concrete request type resolve as before.
