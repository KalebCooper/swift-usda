# Getting Started with FoodData Central

Supply an API key, look up a food, and choose between the everyday methods, reusable requests, and
typed endpoints.

## Overview

FoodData Central is the USDA's food composition database. Every request goes through the
api.data.gov gateway, which requires an API key and limits how often you can call it.

### Supply an API key

Sign up for a free key at [api.data.gov](https://api.data.gov/signup/). Pass it to the client
explicitly: there is no default key, and the library never reads the environment. Keep the key out
of source control and application bundles, because data.gov deactivates keys it finds in public
repositories.

```swift
let configuration = try FoodDataCentralConfiguration(apiKey: apiKey)
let client = FoodDataCentralClient(configuration: configuration)
```

``FoodDataCentralConfiguration/init(apiKey:)`` rejects an empty key, or one containing whitespace
or characters that cannot travel in an HTTP header, with ``FoodDataCentralError/invalidAPIKey``. The
gateway decides whether a key is valid and reports a rejected key as
``FoodDataCentralError/gateway(_:response:)``. The configuration's descriptions redact the key.

The gateway allows 1,000 requests per hour. Exceeding it returns `429` with `OVER_RATE_LIMIT` and
blocks the key for an hour; the client does not retry or wait. For exploration, data.gov's shared
`DEMO_KEY` is documented at 30 requests per hour and 50 per day for each IP address, but responses
were observed with `X-RateLimit-Limit: 10`.

On Linux and Android, enable the package's `HTTPPortable` trait and pass a swifty-networking
transport, such as `AsyncHTTPClientTransport`, to
``FoodDataCentralClient/init(configuration:transport:)``.

### Choose a format

A food lookup comes in two formats. The full format returns the record in the shape its data type
defines, as a case of `Food`: Branded, Foundation, SR Legacy, or Survey (FNDDS), with any other data
type kept whole as JSON. The abridged format returns `AbridgedFood`, one shape for every data type.

```swift
let full = try await client.food(2_346_404)
let abridged = try await client.abridgedFood(2_346_404)
```

To return only some nutrients, pass nutrient numbers. They are sent in the order given. The
FoodData Central specification limits the filter to 25 numbers and describes them as legacy
Standard Reference numbers; no response with a `nutrients` filter has been recorded, so the limit,
which numbers the service matches, and what it returns for a food with none of them are unverified.

```swift
let macros = try NutrientNumbers([203, 204, 205])
let food = try await client.abridgedFood(2_346_404, nutrients: macros)
```

### Look up several foods

To fetch up to 20 foods in one request, validate the identifiers as `FoodIDs` and call
``FoodDataCentralClient/foods(_:nutrients:)`` or ``FoodDataCentralClient/abridgedFoods(_:nutrients:)``.
They accept the same optional nutrient filter as a single lookup. No `/foods` response has been
recorded, so this lookup and its filter follow the specification and are unverified.

```swift
let ids = try FoodIDs([167_782, 2_768_188])
let foods = try await client.foods(ids)
let abridged = try await client.abridgedFoods(ids)
```

`FoodIDs` throws `FoodDataCentralValidationError.foodIDCount` for an empty list or one with more
than 20 identifiers, and `FoodDataCentralValidationError.duplicateFoodID` for a repeat, before any
request is sent. The FoodData Central specification says it omits an identifier it does not know, so
the result can be shorter than the list or empty. It returns the foods in an order it does not
document, so match results to identifiers by each food's `fdcID` instead of by position.

### List foods

To list foods by data type, validate a `FoodListQuery` and read it with
``FoodDataCentralClient/foodListPages(_:)`` for pages or ``FoodDataCentralClient/foods(listing:)``
for foods one at a time. Both are lazy: nothing is sent until you read, and each read fetches one
page.

```swift
let query = try FoodListQuery(
  dataTypes: [.foundation], pageSize: 2, sort: FoodSort(field: .fdcID, order: .descending))
for try await food in client.foods(listing: query) {
  print(food.description)
}
```

`FoodListQuery` throws `FoodDataCentralValidationError.pageNumber` for a page number below 1 and
`FoodDataCentralValidationError.pageSize` for a page size outside 1 to 200, before any request is
sent. <doc:PagingFoodLists> explains where a list ends and what the SDK does not guarantee.

### Search foods

To search, validate a `FoodSearchQuery` and read it with
``FoodDataCentralClient/foodSearchPages(_:)`` for pages or
``FoodDataCentralClient/foods(matching:)`` for foods one at a time. Each read posts one page, and
the search continues while the reported `currentPage` is below `totalPages`.

```swift
let query = try FoodSearchQuery("cheddar cheese", dataTypes: [.branded], pageSize: 25)
for try await food in client.foods(matching: query) {
  print(food.fdcID, food.description)
}
```

`FoodSearchQuery` throws `FoodDataCentralValidationError.emptySearchQuery` for search terms that
are empty or only whitespace, before any request is sent. No search response has been recorded, so
the result shapes follow the specification and are unverified. <doc:SearchingFoods> covers the
filters, sort names, and what the SDK does not guarantee.

### Choose a level

Each lookup is available at three equivalent levels, and all of them send the same request with the
same authentication and errors:

- The everyday methods, ``FoodDataCentralClient/food(_:nutrients:)``,
  ``FoodDataCentralClient/abridgedFood(_:nutrients:)``, ``FoodDataCentralClient/foods(_:nutrients:)``,
  and ``FoodDataCentralClient/abridgedFoods(_:nutrients:)``.
- A reusable `FoodRequest`, executed with `value(for:)`. A request is a
  value you can store, compare, and pass around before sending it.
- A typed `Endpoint`, sent with ``FoodDataCentralClient/send(_:)``. An endpoint is the single HTTP
  request, and you can also execute it with a networking stack of your own.

```swift
let request: FoodRequest<Food> = .food(2_346_404)
let fromRequest = try await client.value(for: request)

let endpoint = Endpoint<Food>.food(2_346_404)
let fromEndpoint = try await client.send(endpoint)
```

The multiple-food lookups work the same way: `FoodRequest<[Food]>.foods(_:nutrients:)` and
`Endpoint<[Food]>.foods(_:nutrients:)`, with `abridgedFoods` for `[AbridgedFood]`.

### Handle errors

Every operation throws ``FoodDataCentralError``:

- ``FoodDataCentralError/gateway(_:response:)`` carries the gateway's error body, with codes such
  as `API_KEY_MISSING`, `API_KEY_INVALID`, and `OVER_RATE_LIMIT`, and the original HTTP response.
- ``FoodDataCentralError/transport(_:)`` covers everything else: connection, cancellation, and
  decoding failures, and HTTP statuses without a gateway body, such as `404` for an unknown food
  identifier. FoodData Central documents `404` and `400` on a food lookup, but those bodies have
  not been recorded.
- ``FoodDataCentralError/invalidAPIKey`` comes only from creating a configuration.

```swift
do {
  let food = try await client.food(2_346_404)
} catch .gateway(let response, _) {
  print(response.error.code)
} catch {
  print(error)
}
```
