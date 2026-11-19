# Paging Through Food Lists

List foods page by page or food by food, and know what the SDK does and does not promise about
where a list ends.

## Overview

FoodData Central's `/foods/list` returns a bare array of abridged foods for one page number and
page size. It sends no total, no page count, and no "last page" flag. The client turns that into
lazy sequences: ``FoodDataCentralClient/foodListPages(_:)`` yields a ``FoodListPageSequence`` of
`FoodListPage` values, and ``FoodDataCentralClient/foods(listing:)`` yields a
``FoodListItemSequence`` of `AbridgedFood` values in the same order.

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

Pages are numbered from 1. Nothing is sent when a sequence or an iterator is created. Each read
fetches exactly one page, with no prefetch, and each iterator starts its own traversal from the
query's first page. Breaking out of a loop sends nothing more. Every request carries the API key in
the `X-Api-Key` header and reports the same errors as a single lookup.

To fetch one page without continuing, use `client.value(for: .foodList(query))`, which returns a
`FoodListPage`, or ``FoodDataCentralClient/send(_:)`` with `Endpoint.foodList(_:)`, which returns
the bare array of foods.

### How a list ends

The SDK ends a list at the first page that holds fewer foods than the page size, including an empty
page. That is the SDK's reading of the response, not a guarantee from FoodData Central, which
documents no terminal signal for this endpoint.

One consequence follows from the rule. When the number of foods in a list is an exact multiple of
the page size, the last full page does not look final, so the sequence requests one more page,
receives an empty array, yields that empty page, and stops. Expect one extra request, and one empty
`FoodListPage`, in that case.

```swift
for try await page in client.foodListPages(query) {
  if page.foods.isEmpty { print("Nothing left after page", page.pageNumber - 1) }
}
```

The rule is also checked against every page it reads. A page that reports a different page number
or page size from the request it answers, or that holds more foods than its page size, ends the
iteration with ``FoodDataCentralError/pagination(_:)`` before that page is yielded, rather than
guessing a successor. The same happens if the next page number would not fit in an `Int`.
`FoodListQuery.next(after:)` applies the same rule to a page you hold, if you drive the requests
yourself.

### The result window

FoodData Central limits how deep a list can page and does not document the limit. It refuses a page
with a `400` and the plain-text body "Bad Request: pageSize * pageNumber exceeded upper search
results limit." When recorded on Branded foods with a page size of 2, page 50,000 (100,000 foods
deep) was answered and page 50,001 (100,002 deep) was refused, so the window observed is a page
number times page size of at most 100,000. The service documents no limit and may change it.

Inside ``FoodListPageSequence`` and ``FoodListItemSequence``, a `400` whose body is exactly that
text arrives as ``FoodDataCentralError/pagination(_:)`` with
`FoodPaginationError.resultWindowExceeded`. The service sends no error code, so the match is on
the exact body text; any other `400` stays ``FoodDataCentralError/transport(_:)``. A single page
fetched with `value(for:)` or ``FoodDataCentralClient/send(_:)`` does not make that distinction and
reports the refusal as ``FoodDataCentralError/transport(_:)`` with the original body.

```swift
do {
  for try await food in client.foods(listing: query) { print(food.fdcID) }
} catch .pagination(.resultWindowExceeded) {
  print("The list is deeper than FoodData Central will page.")
} catch {
  print(error)
}
```

### Lists change while you read them

Each page is a separate request, and FoodData Central gives no snapshot guarantee across them. If
foods are added, removed, or reordered between two requests, a later page can repeat a food an
earlier page returned, skip one, or end earlier or later than the list you started with. The service
does not document its default order for an unsorted list or its default direction for a sort
without one, and it publishes no update schedule. If you need every food exactly once, sort by
a stable field and de-duplicate by each food's `fdcID` as you read.

### Sort names

`FoodSortField` is open. `fdcId` is confirmed by a recorded response. The other names,
`dataType.keyword`, `lowercaseDescription.keyword`, and `publishedDate`, come from the FoodData
Central specification and have not been recorded. The specification warns that the two `.keyword`
names will change; the service still rejects the announced replacement, `sortBy=description`, with a
`400`. If a name changes, create the field with `FoodSortField/init(rawValue:)`.

### Errors during a traversal

Any failure ends the iterator, and every later read returns `nil`. Cancellation is checked before
each request and again before each page or food is returned, including foods already buffered from
the current page, and arrives as ``FoodDataCentralError/transport(_:)`` with `cancelled`. Gateway
refusals such as `OVER_RATE_LIMIT` arrive as ``FoodDataCentralError/gateway(_:response:)``. The
client does not retry, wait, or track the rate limit, so a long traversal counts each page against
the key's hourly allowance (documented as 1,000 requests).

## Topics

### Reading a list

- ``FoodDataCentralClient/foodListPages(_:)``
- ``FoodDataCentralClient/foods(listing:)``
- ``FoodListPageSequence``
- ``FoodListItemSequence``

### Reading a list request

- ``FoodDataCentralClient/pages(for:)->FoodListPageSequence``
- ``FoodDataCentralClient/items(for:)->FoodListItemSequence``
