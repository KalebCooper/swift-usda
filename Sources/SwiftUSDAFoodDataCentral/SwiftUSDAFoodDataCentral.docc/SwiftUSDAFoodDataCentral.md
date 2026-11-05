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
