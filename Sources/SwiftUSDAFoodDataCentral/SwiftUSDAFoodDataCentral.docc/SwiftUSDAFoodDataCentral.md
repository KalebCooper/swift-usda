# ``SwiftUSDAFoodDataCentral``

Look up foods and their nutrients from USDA FoodData Central.

## Overview

Start with ``FoodDataCentralClient`` and a data.gov API key. These examples use the Apple-platform
initializer; use ``FoodDataCentralClient/init(configuration:transport:)`` for a custom networking
setup or on Linux and Android.

```swift
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels

let client = try FoodDataCentralClient(apiKey: apiKey)
let food = try await client.abridgedFood(2_346_404)
print(food.description)
```

Request the full format to get the record in the shape its data type defines:

```swift
switch try await client.food(2_346_404) {
case .branded(let food): print(food.brandOwner ?? "No brand owner", food.description)
case .foundation(let food): print(food.description)
case .other(let dataType, _): print("Not modeled:", dataType.rawValue)
case .srLegacy(let food): print(food.description)
case .survey(let food): print(food.description)
}
```

To fetch up to 20 foods in one request, validate the identifiers as `FoodIDs`. The FoodData Central
specification says unknown identifiers are omitted, and the rest come back in an order it does not
document:

```swift
let foods = try await client.abridgedFoods(try FoodIDs([167_782, 2_768_188]))
```

To list foods, validate a `FoodListQuery` and read it page by page or food by food. Each read
fetches one page, and the sequence ends at the first page shorter than the page size, which is the
SDK's reading of the response rather than a guarantee from FoodData Central. See
<doc:PagingFoodLists>.

```swift
let query = try FoodListQuery(dataTypes: [.foundation], pageSize: 2)
for try await page in client.foodListPages(query) {
  print(page.pageNumber, page.foods.map(\.fdcID))
}
```

The client sends the key in the `X-Api-Key` header, never in the URL, and checks cancellation before
every request. It does not retry, follow redirects, cache, or track the gateway's rate limit.
Operations throw ``FoodDataCentralError``. Credential and rate-limit refusals from the api.data.gov
gateway arrive as ``FoodDataCentralError/gateway(_:response:)``; an unknown food identifier (`404`)
arrives as ``FoodDataCentralError/transport(_:)`` with the original body.

FoodData Central publishes no update schedule, so the API guarantees no data freshness. Its data is
in the public domain under CC0 1.0, and FoodData Central asks to be credited as the source.

## Topics

### Essentials

- <doc:GettingStarted>
- ``FoodDataCentralClient``
- ``FoodDataCentralConfiguration``
- ``FoodDataCentralError``

### Listing foods

- <doc:PagingFoodLists>
- ``FoodDataCentralClient/foodListPages(_:)``
- ``FoodDataCentralClient/foods(listing:)``
- ``FoodDataCentralClient/pages(for:)``
- ``FoodDataCentralClient/items(for:)``
- ``FoodListPageSequence``
- ``FoodListItemSequence``
