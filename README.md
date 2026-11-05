# swift-usda

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Food records and nutrients from USDA FoodData Central, with Swift types and `async`/`await`.

## Status

Food lookup by FoodData Central identifier works today, one food at a time or several at once
(`/foods`, one to 20 identifiers per request), in the full and abridged formats, with an optional
filter of up to 25 nutrients. Full-format records decode in the shape of their data type:
Branded, Foundation, SR Legacy, and Survey (FNDDS). Records of any other data type, such as
Experimental, are kept whole as JSON.

Each modeled shape is checked against a response recorded from the live API: one full record of
each of the four data types, and abridged Foundation and Branded records. Fields documented in the
FoodData Central specification but absent from those responses are optional and unverified. A field
the models do not declare is not kept when a record decodes; only records of an unmodeled data type,
and a Survey input food's nested record, are kept whole.

Not yet built: food lists (`/foods/list`) and food search (`/foods/search`).

What FoodData Central does not guarantee:

- **Multiple-food results.** The FoodData Central specification says `/foods` omits identifiers it
  does not know, so a result can be shorter than the request or empty. It returns foods in an order
  it does not document, so match results to identifiers by each food's `fdcID`.
- **Freshness.** FoodData Central publishes no update schedule, so the API guarantees no data
  freshness.
- **Rate limits.** The api.data.gov gateway allows 1,000 requests per hour. Exceeding it
  returns `429` and blocks the key for an hour. The client does not retry, wait, or track the limit.
- **The shared demo key.** data.gov's `DEMO_KEY` allows 30 requests per hour and 50 per day for each
  IP address. It is for exploration, not for applications.

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

Each lookup is also available as a reusable `FoodRequest`, sent with `value(for:)`, and as a typed
`Endpoint`, sent with `send(_:)` or with a networking stack of your own. Operations throw
`FoodDataCentralError`.

## Example

Look up a food in the full format, limited to protein, fat, and carbohydrate:

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

An unknown identifier arrives as `FoodDataCentralError.transport` with the `404` response. Credential
and rate-limit refusals arrive as `.gateway` with the gateway's code, such as `API_KEY_INVALID` or
`OVER_RATE_LIMIT`.

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
