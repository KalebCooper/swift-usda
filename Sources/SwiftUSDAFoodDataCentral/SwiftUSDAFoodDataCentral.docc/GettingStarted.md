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
`DEMO_KEY` allows 30 requests per hour and 50 per day for each IP address.

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

To return only some nutrients, pass up to 25 nutrient numbers. They are sent in the order given; a
food with none of them comes back with an empty nutrient list rather than an error.

```swift
let macros = try NutrientNumbers([203, 204, 205])
let food = try await client.abridgedFood(2_346_404, nutrients: macros)
```

### Choose a level

Each lookup is available at three equivalent levels, and all of them send the same request with the
same authentication and errors:

- The everyday methods, ``FoodDataCentralClient/food(_:nutrients:)`` and
  ``FoodDataCentralClient/abridgedFood(_:nutrients:)``.
- A reusable `FoodRequest`, executed with ``FoodDataCentralClient/value(for:)``. A request is a
  value you can store, compare, and pass around before sending it.
- A typed `Endpoint`, sent with ``FoodDataCentralClient/send(_:)``. An endpoint is the single HTTP
  request, and you can also execute it with a networking stack of your own.

```swift
let request: FoodRequest<Food> = .food(2_346_404)
let fromRequest = try await client.value(for: request)

let endpoint = Endpoint<Food>.food(2_346_404)
let fromEndpoint = try await client.send(endpoint)
```

### Handle errors

Every operation throws ``FoodDataCentralError``:

- ``FoodDataCentralError/gateway(_:response:)`` carries the gateway's error body, with codes such
  as `API_KEY_MISSING`, `API_KEY_INVALID`, and `OVER_RATE_LIMIT`, and the original HTTP response.
- ``FoodDataCentralError/transport(_:)`` covers everything else: connection, cancellation, and
  decoding failures, and HTTP statuses without a gateway body, such as `404` for an unknown food
  identifier.
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
