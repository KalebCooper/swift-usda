# swift-usda

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Food records and nutrients from USDA FoodData Central, with Swift types and `async`/`await`.

## Status

Four FoodData Central endpoints work today: food lookup by identifier (`/food/{fdcId}`), several
foods at once (`/foods`, one to 20 identifiers per request), food lists (`/foods/list`), and food
search (`/foods/search`). Lookups come in the full and abridged formats, with an optional
`nutrients` filter. Full-format records decode in the shape of their data type: Branded,
Foundation, SR Legacy, and Survey (FNDDS). A record of any other data type, such as a full
Experimental record, is kept whole as JSON by design.

Food lists (`/foods/list`) work too: abridged foods filtered by data type and optionally sorted,
read lazily as pages or as single foods, one request per page. Each of the five data types
(Branded, Experimental, Foundation, SR Legacy, and Survey) was recorded from the live API.

Food search (`/foods/search`) works as well: search terms with optional data type, brand owner,
trade channel, and publication date filters and a sort, posted as a JSON body and read lazily as
pages or as single foods, one request per page.

Every endpoint is checked against responses recorded from the live API: one full record of each of
the four modeled data types and an Experimental record, abridged records, `/foods` responses
(including one with an unknown identifier and one with none known), list pages, search pages with
each filter and a sort, and the error bodies of `/food/{id}`. A few things remain unrecorded:

- **The `nutrients` limits.** The filter matches legacy nutrient numbers such as `203`, not nutrient
  IDs such as `1003`, and keeps only the requested nutrients. The 25-number limit comes from the
  specification, and what the service returns for a food with none of the requested nutrients has
  not been recorded.
- **Unmodeled fields.** Fields documented in the specification but absent from the recorded
  responses are optional and unverified. A field the models do not declare is not kept when a record
  decodes; only records of an unmodeled data type, and a Survey input food's nested record, are kept
  whole.

What FoodData Central does not guarantee:

- **Multiple-food results.** `/foods` omits identifiers it does not know, so a result can be shorter
  than the request. When it knows none of them it answers `{}` rather than `[]`, which the SDK and
  `Endpoint.decode(_:)` return as an empty array. It returns foods in an order it does not document
  (one recorded response followed the request and another did not), so match results to
  identifiers by each food's `fdcID`.
- **Where a list ends.** `/foods/list` sends a bare array with no total or last-page flag. The
  sequences treat the first page with fewer foods than the page size as the last, which is the
  SDK's reading, not a service guarantee; a list whose length is a multiple of the page size costs
  one extra request that returns an empty page.
- **A list is not a snapshot.** Each page is a separate request. If FoodData Central changes between
  them, a food can repeat or be skipped, and the service documents no default order.
- **How deep a list can page.** FoodData Central refuses list pages past an undocumented result
  window with a `400`. When recorded, a page number times page size of 100,000 was answered and
  100,002 was refused. The sequences report the refusal as
  `FoodDataCentralError.pagination(.resultWindowExceeded)`, recognized by the service's exact
  response text. Fetching a single page reports it as `.transport`.
- **How deep a search can page.** No search refusal has been observed: search pages at a page
  number times page size of 10,002 were answered normally. The search window is unknown; the search
  sequences recognize the list's refusal text in case search sends it.
- **Search result spellings.** Recorded search responses spell a nutrient's amount `value` and a
  food's date `publishedDate`; the specification (version 1.0.1) spells them `amount` and
  `publicationDate`. Both spellings are accepted, the service's first. The echoed search criteria
  are decoded leniently and never used to continue.
- **Search filters.** The data type, trade channel, and publication date filters, accepted only in
  a `POST` body, are echoed and applied. The brand owner is echoed but is not a strict filter: a
  recorded Branded search for one owner also returned a food of another.
- **Where a search ends.** A search continues while the reported `currentPage` is below
  `totalPages`. Those totals are the service's figures for each page, results can change between
  requests, and pages are not a snapshot. Pages are numbered from 1 (page 0 returns the same bytes
  as page 1). A page past the last is answered with `currentPage` 1 and no foods, which the
  sequences report as `.pagination(.unexpectedPageNumber(actual:expected:))`.
- **Empty search terms.** The service answers empty search terms with every food. The SDK rejects
  empty or whitespace-only terms before sending, by choice.
- **Sort names.** `fdcId` is the only sort name confirmed by a recorded response. The specification
  warns that `dataType.keyword` and `lowercaseDescription.keyword` will change, but the announced
  replacement `description` was refused with a `400` when recorded.
- **Freshness.** FoodData Central publishes no update schedule, so the API guarantees no data
  freshness.
- **Rate limits.** The FoodData Central guide documents 1,000 requests per hour; one key was
  observed with `X-RateLimit-Limit: 3600`. Neither figure is promised: read the
  `X-RateLimit-Limit` and `X-RateLimit-Remaining` headers. Exceeding the limit returns `429` and
  blocks the key for an hour. The client does not retry, wait, or track the limit.
- **The shared demo key.** data.gov's documentation says `DEMO_KEY` allows 30 requests per hour and
  50 per day for each IP address, but responses were observed with `X-RateLimit-Limit: 10`. It is
  for exploration, not for applications.

Identifiers, units, dates, and missing values are kept as FoodData Central sends them. Nothing is
converted, defaulted, or filtered, except that a field FoodData Central sends as an integer in some
responses and a string in others, such as `ndbNumber`, decodes into one string.

## Usage

Get a free data.gov API key at [api.data.gov](https://api.data.gov/signup/) and pass it to the
client. There is no default key, and the library never reads the environment. Keep the key out of
source control and application bundles: data.gov deactivates keys it finds in public repositories.
The client sends the key in the `X-Api-Key` header, never in the URL.

```swift
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels

let client = try FoodDataCentralClient(apiKey: apiKey)
let food = try await client.abridgedFood(2_346_404)
print(food.description)
```

To fetch up to 20 foods in one request, validate the identifiers as `FoodIDs` and call
`foods(_:nutrients:)` or `abridgedFoods(_:nutrients:)`:

```swift
let foods = try await client.abridgedFoods(try FoodIDs([167_782, 2_768_188]))
```

An empty list, more than 20 identifiers, or a repeat throws `FoodDataCentralValidationError` before
any request is sent.

To list foods, validate a `FoodListQuery` and read it lazily. Nothing is sent until you read, and
each read fetches one page of up to `pageSize` foods (1 to 200, default 50), numbered from page 1:

```swift
let query = try FoodListQuery(
  dataTypes: [.foundation], pageSize: 2, sort: FoodSort(field: .fdcID, order: .descending))

for try await page in client.foodListPages(query) {
  print(page.pageNumber, page.foods.map(\.fdcID))
}

for try await food in client.foods(listing: query) {
  print(food.description)
}
```

A page number below 1 or a page size outside 1 to 200 throws `FoodDataCentralValidationError` before
any request is sent. To fetch just one page, call `client.value(for: .foodList(query))`.

To search, validate a `FoodSearchQuery` and read it the same way. The search terms are sent exactly
as given and may use FoodData Central's search operators:

```swift
let search = try FoodSearchQuery("cheddar cheese", dataTypes: [.branded], pageSize: 25)

for try await page in client.foodSearchPages(search) {
  print(page.currentPage, page.totalPages, page.totalHits)
}

for try await food in client.foods(matching: search) {
  print(food.fdcID, food.description)
}
```

Empty or whitespace-only search terms throw `FoodDataCentralValidationError` before any request is
sent. To fetch just one page, call `client.value(for: .foodSearch(search))`.

Each lookup is also available as a reusable `FoodRequest`, sent with `value(for:)`, and as a typed
`Endpoint`, sent with `send(_:)` or with a networking stack of your own. Operations throw
`FoodDataCentralError`.

## Example

Look up a food in the full format, asking for protein, fat, and carbohydrate by their legacy
nutrient numbers:

```swift
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels

let client = try FoodDataCentralClient(apiKey: apiKey)
let macros = try NutrientNumbers([203, 204, 205])

do {
  switch try await client.food(2_346_404, nutrients: macros) {
  case .branded(let food): print(food.brandOwner ?? "No brand owner", food.description)
  case .foundation(let food): print(food.description)
  case .other(let dataType, _): print("Not modeled:", dataType.rawValue)
  case .srLegacy(let food): print(food.description)
  case .survey(let food): print(food.description)
  }
} catch .gateway(let response, _) {
  print("Gateway refused the request:", response.error.code)
} catch {
  print(error)
}
```

An unknown identifier is a `404` with an empty body, and a malformed one a `400`; both arrive as
`FoodDataCentralError.transport` with the response. Credential and rate-limit refusals arrive as `.gateway` with the gateway's code, such as `API_KEY_INVALID` or
`OVER_RATE_LIMIT`.

The [SwiftUI demo app](Examples/SwiftUSDAFoodDataCentralDemo) searches foods, loads more results a
page at a time, and shows the full record for a food. It keeps your entered key in memory.
Open [SwiftUSDAFoodDataCentralDemo.xcodeproj](Examples/SwiftUSDAFoodDataCentralDemo/SwiftUSDAFoodDataCentralDemo.xcodeproj)
in Xcode with the standalone package window closed, since Xcode opens a local package in only one
window at a time.

## Products

| Product | Contents |
| --- | --- |
| `SwiftUSDAFoodDataCentral` | `FoodDataCentralClient`, `FoodDataCentralConfiguration`, and `FoodDataCentralError`, built on [swifty-networking](https://github.com/KalebCooper/swifty-networking). |
| `SwiftUSDAFoodDataCentralModels` | `Codable` food records, validated inputs, `FoodRequest`, and `Endpoint` values, with no networking dependency, for use with your own networking stack. |

## Requirements

Requires Swift 6.2 or later. Supports iOS, macOS, tvOS, visionOS, and watchOS 26 or later, and
Linux, which is tested with and without the `HTTPPortable` trait. Android builds use the same
`HTTPPortable` trait but are not yet verified, and hosted CI is not yet running.

## Installation

No version has been released yet, so depend on the `main` branch until the first release.

In Xcode, add `https://github.com/KalebCooper/swift-usda` as a package dependency and select the
products you need. For a Swift package, add:

```swift
.package(url: "https://github.com/KalebCooper/swift-usda.git", branch: "main")
```

Then add the products to your target's dependencies:

```swift
.product(name: "SwiftUSDAFoodDataCentral", package: "swift-usda"),
.product(name: "SwiftUSDAFoodDataCentralModels", package: "swift-usda"),
```

On Linux and Android, also add `traits: ["HTTPPortable"]` to the package dependency and supply an
`AsyncHTTPClientTransport` from [swifty-networking](https://github.com/KalebCooper/swifty-networking)
to the client's `transport:` initializer. The examples above use the Apple-platform initializer.

## License

MIT. See [LICENSE](LICENSE).

Data comes from [USDA FoodData Central](https://fdc.nal.usda.gov/), which is in the public domain
under CC0 1.0. FoodData Central asks to be credited as the source.
