# FoodData Central example

Open `SwiftUSDAFoodDataCentralDemo.xcodeproj`, select the generated app scheme and an iOS 26 or newer
simulator, then run. Close the standalone package workspace first so Xcode resolves one package copy.
The app depends on the repository by local path and uses both public products.

Enter your api.data.gov key and search terms, then choose Search. The app reads the search with
`foods(matching:)` and shows one page of 25 foods; Load more reads the next page only when you choose
it. Editing the key or the search terms discards the results and cancels a request in flight. Cancel stops a load, keeps the foods already loaded, and ends that
search; choose Search to start over. Select a
food to request its full record with `food(_:)`. The detail screen shows the fields of its data type
(Branded, Foundation, SR Legacy, or Survey (FNDDS)), its nutrients in the units FoodData Central
reports, and its portions with gram weights. A data type without a typed model is shown by name with
its record kept as JSON.

Your key stays in memory and is sent only to FoodData Central in the `X-Api-Key` header. It is never
saved or logged. An empty key, or one that cannot travel in an HTTP header, shows
`FoodDataCentralError.invalidAPIKey` and sends nothing. A key the gateway rejects shows the gateway's
error code, such as `API_KEY_INVALID` or `OVER_RATE_LIMIT`.

FoodData Central publishes no update schedule and gives no snapshot across search pages, so a later
page can repeat or skip a food. Data comes from USDA FoodData Central and is in the public domain
(CC0 1.0).
