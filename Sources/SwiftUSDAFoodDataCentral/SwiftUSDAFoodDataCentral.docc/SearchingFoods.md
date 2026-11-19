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
`FoodDataCentralValidationError.emptySearchQuery` otherwise. That is this package's choice: the
service itself answers empty terms with every food, which is not a search. The terms are sent exactly as given,
surrounding spaces included, and may use FoodData Central's search operators; see the
[FoodData Central API guide](https://fdc.nal.usda.gov/api-guide). The SDK does not interpret or
check them.

### Filters

`FoodSearchQuery` accepts a set of data types, which sends no filter when empty, and a brand owner.
The brand owner is sent exactly as given, with no validation, and applies only to Branded foods. The
service echoes it but does not apply it strictly: a recorded Branded search for one owner also
returned a food of another, so check `brandOwner` on each result if you need an exact match.

The trade channel filter (`TradeChannel`, up to three) and the publication date range
(`FoodPublicationDate`, a start no later than the end) are accepted only in a `POST` body. Recorded
searches show the service echoes and applies both. Version 1.0.0 of the FoodData Central
specification, which the service still serves, does not list them; the three-channel limit comes
from version 1.0.1.

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

Pages are numbered from 1: the service answers page 0 with the same bytes as page 1. A start page
past the last is answered with `currentPage` 1 and no foods, so a sequence started there ends with
`FoodPaginationError.unexpectedPageNumber(actual:expected:)` without yielding that page.

### The result window

FoodData Central refuses a food list page deep in its results with a `400` and the plain-text body
"Bad Request: pageSize * pageNumber exceeded upper search results limit." No search refusal has
been observed: search pages at a page number times page size of 10,002 were answered normally, and
the search window is unknown. In case search refuses a page the same way, inside
``FoodSearchPageSequence`` and
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

### Response shapes

`FoodSearchResult`, `SearchResultFood`, and `SearchResultFoodNutrient` are checked against recorded
responses. The service answers with one object, as version 1.0.1 of the specification types it;
version 1.0.0 types it as an array. The service spells some fields differently from the
specification, and decoding accepts both spellings, the service's first: a nutrient's `value`,
`nutrientName`, `nutrientNumber`, and `nutrientId`, or `amount`, `name`, and `number`; and a food's
`publishedDate` or `publicationDate`. Encoding always writes the service's spelling.

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
key's hourly allowance (documented as 1,000 requests).

## Topics

### Searching

- ``FoodDataCentralClient/foodSearchPages(_:)``
- ``FoodDataCentralClient/foods(matching:)``
- ``FoodSearchPageSequence``
- ``FoodSearchItemSequence``

### Searching with a request

- ``FoodDataCentralClient/pages(for:)->FoodSearchPageSequence``
- ``FoodDataCentralClient/items(for:)->FoodSearchItemSequence``
