# Changelog

All notable changes are documented here, following
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/).

## Unreleased

### Added

- `SwiftUSDAFoodDataCentralModels`, a product with no networking dependency: `Endpoint`, the
  `FoodRequest` request type with its public `resolution`, and
  `Endpoint.food(_:nutrients:)` and `Endpoint.abridgedFood(_:nutrients:)` for
  `GET /food/{fdcId}` in the full and abridged formats.
- Full-format records as the `Food` enum, decoded by data type into `BrandedFood`,
  `FoundationFood`, `SRLegacyFood`, and `SurveyFood`, with any other data type kept whole as
  `.other(dataType:_:)`. Abridged records as `AbridgedFood`.
- Public memberwise initializers on every response model. `ndbNumber` and `FoodAttribute.value`
  decode from a JSON integer or string into one string.
- Validated inputs `FoodID`, `NutrientNumber`, and `NutrientNumbers` (one to 25 distinct nutrients),
  the open `FoodDataType`, and `FoodDataCentralValidationError`.
- `DataGovErrorResponse` for api.data.gov gateway error bodies, and `JSONValue` for records kept
  whole.
- `SwiftUSDAFoodDataCentral`, a product with `FoodDataCentralClient`, which offers `food(_:nutrients:)`,
  `abridgedFood(_:nutrients:)`, `value(for:)`, and `send(_:)`, sends the API key in the `X-Api-Key`
  header, and checks cancellation before every request.
- `FoodDataCentralConfiguration` with a required API key, and the typed `FoodDataCentralError` with
  `gateway`, `invalidAPIKey`, and `transport` cases.
- Multiple-food lookup for `GET /foods`: `FoodIDs` (one to 20 distinct identifiers),
  `Endpoint.foods(_:nutrients:)` and `Endpoint.abridgedFoods(_:nutrients:)`,
  `FoodRequest.foods(_:nutrients:)` and `FoodRequest.abridgedFoods(_:nutrients:)`, and the client
  methods `foods(_:nutrients:)` and `abridgedFoods(_:nutrients:)`. The specification says unknown
  identifiers are omitted; the service's result order is undocumented.
- `FoodDataCentralValidationError.duplicateFoodID` and `.foodIDCount`.
- An `HTTPPortable` trait for Linux and Android transports.
- DocC documentation for both products.
