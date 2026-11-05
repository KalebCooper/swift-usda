# Searching Foods

Search foods page by page or food by food, and know which parts of the search API are recorded and
which come only from its specification.

## Overview

FoodData Central's `/foods/search` takes search terms and optional filters and returns one page of
matching foods with the totals it reports for the search: `totalHits`, `currentPage`, and
`totalPages`. The client posts each page as a JSON body and turns the pages into lazy sequences:
``FoodDataCentralClient/foodSearchPages(_:)`` yields a ``FoodSearchPageSequence`` of
`FoodSearchResult` values, and ``FoodDataCentralClient/foods(matching:)`` yields a
``FoodSearchItemSequence`` of `SearchResultFood` values in the same order.

```swift
let query = try FoodSearchQuery("cheddar cheese", dataTypes: [.branded], pageSize: 50)

for try await page in client.foodSearchPages(query) {
  print(page.currentPage, page.totalPages, page.foods.count)
}

for try await food in client.foods(matching: query) {
  print(food.fdcID, food.description)
}
```

Nothing is sent when a sequence or an iterator is created. Each read posts exactly one page, with
no prefetch, and each iterator starts its own traversal from the query's page. Breaking out of a
loop sends nothing more. Every request carries the API key in the `X-Api-Key` header, never in the
URL or the body, and reports the same errors as a single lookup.

To fetch one page without continuing, use `client.value(for: .foodSearch(query))` or
``FoodDataCentralClient/send(_:)`` with `Endpoint.foodSearch(_:)`. Both return a
`FoodSearchResult`. For a stored `FoodRequest<FoodSearchResult>`, `pages(for:)` and `items(for:)`
return the same sequences as the query-based methods.

### Search terms

The search terms must hold something other than whitespace; `FoodSearchQuery` throws
`FoodDataCentralValidationError.emptySearchQuery` otherwise. The terms are sent exactly as given,
surrounding spaces included, and may use FoodData Central's search operators; see the
[FoodData Central API guide](https://fdc.nal.usda.gov/api-guide). The SDK does not interpret or
check them.

### Filters

`FoodSearchQuery` accepts a set of data types, which sends no filter when empty, and a brand owner.
The brand owner is sent exactly as given, with no validation, and applies only to Branded foods.

The trade channel filter (`TradeChannel`, up to three) and the publication date range
(`FoodPublicationDate`, a start no later than the end) come from the FoodData Central
specification, version 1.0.1, which accepts them only in a `POST` body. They are spec-derived and
have not been verified against the service, so a search that uses them may return foods the filter
was meant to exclude. Version 1.0.0 of the specification, which the service still serves, does not
list them.

### Sort names

A search takes the same `FoodSort` as a food list. The specification warns that the two `.keyword`
sort names, `dataType.keyword` and `lowercaseDescription.keyword`, will be renamed to `dataType`
and `description`. The rename is not live: the service answers `sortBy=description` with a `400`, so
`FoodSortField` keeps the `.keyword` names. If a name changes, create the field with
`FoodSortField.init(rawValue:)`. Without a sort, results come in the service's relevance order,
which it does not document.

### How a search ends

The search continues with `FoodSearchQuery.next(after:)` while a page's `currentPage` is below its
`totalPages`, keeping the search terms, filters, page size, and sort, and ends at the page that
reaches or passes the reported page count. A search that matches nothing yields one empty page and
ends. If the page count shrinks below the current page between requests, the search ends after
that page.

Every page is checked against the query it answers before it is yielded. A page that reports
another page number, including a repeat of an earlier page, holds more foods than its page size, or
reports totals that contradict each other or the page ends the iteration with
``FoodDataCentralError/pagination(_:)``. The page count is not checked against the hit count and
page size, because FoodData Central does not document how it computes it.

Pages are numbered from 1. That base was recorded for the food list, where page 0 returns the same
foods as page 1, and is assumed for search, where it has not been recorded.

### The result window

FoodData Central refuses a food list page deep in its results with a `400` and the plain-text body
"Bad Request: pageSize * pageNumber exceeded upper search results limit." No search refusal has
been recorded. The same body is assumed for search, so inside ``FoodSearchPageSequence`` and
``FoodSearchItemSequence`` a `400` with exactly that text arrives as
``FoodDataCentralError/pagination(_:)`` with `FoodPaginationError.resultWindowExceeded`, and any
other `400` stays ``FoodDataCentralError/transport(_:)``. A single page fetched with `value(for:)`
or ``FoodDataCentralClient/send(_:)`` reports the refusal as ``FoodDataCentralError/transport(_:)``
with the original body.

```swift
do {
  for try await food in client.foods(matching: query) { print(food.fdcID) }
} catch .pagination(.resultWindowExceeded) {
  print("The search is deeper than FoodData Central will page.")
} catch {
  print(error)
}
```

### Unverified response shapes

No search response has been recorded. `FoodSearchResult`, `SearchResultFood`, and
`SearchResultFoodNutrient` follow the FoodData Central specification, version 1.0.1, which types the
response as one object; version 1.0.0 types it as an array. Where the service is understood to
spell a field differently from the specification, decoding accepts both spellings, the service's
first: a nutrient's `value`, `nutrientName`, `nutrientNumber`, and `nutrientId`, or `amount`,
`name`, and `number`; and a food's `publishedDate` or `publicationDate`. Neither spelling is
verified against a recording, and encoding always writes the service's spelling.

The criteria the service echoes back, `FoodSearchCriteria`, are decoded leniently: an echo of
another shape becomes `nil` instead of failing the page. Continuation never reads the echo; it
continues from the query that was sent.

### Searches change while you read them

Each page is a separate request, and FoodData Central gives no snapshot guarantee across them. The
totals are the service's figures for each page received. If foods are added, removed, or rescored
between two requests, a later page can repeat a food, skip one, or end earlier or later than the
search you started. FoodData Central publishes no update schedule. If you need every food exactly
once, de-duplicate by each food's `fdcID` as you read.

### Errors during a traversal

Any failure ends the iterator, and every later read returns `nil`. Cancellation is checked before
each request and again before each page or food is returned, including foods already buffered from
the current page, and arrives as ``FoodDataCentralError/transport(_:)`` with `cancelled`. Gateway
refusals such as `OVER_RATE_LIMIT` arrive as ``FoodDataCentralError/gateway(_:response:)``. The
client does not retry, wait, or track the rate limit, so a long search counts each page against the
1,000-request hourly allowance.

## Topics

### Searching

- ``FoodDataCentralClient/foodSearchPages(_:)``
- ``FoodDataCentralClient/foods(matching:)``
- ``FoodSearchPageSequence``
- ``FoodSearchItemSequence``

### Searching with a request

- ``FoodDataCentralClient/pages(for:)->FoodSearchPageSequence``
- ``FoodDataCentralClient/items(for:)->FoodSearchItemSequence``
