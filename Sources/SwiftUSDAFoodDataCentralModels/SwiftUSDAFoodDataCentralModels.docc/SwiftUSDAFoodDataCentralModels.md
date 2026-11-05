# ``SwiftUSDAFoodDataCentralModels``

Describe USDA FoodData Central requests and decode its food records with any networking stack.

## Overview

Use this library for response models, validated inputs, and request descriptions without
networking dependencies. Add `SwiftUSDAFoodDataCentral` when you want a client to send the requests
for you.

``Endpoint`` describes one request: a path and query relative to
`https://api.nal.usda.gov/fdc/v1`, an ``EndpointMethod``, and, for a search, a JSON body.
``FoodRequest`` describes an operation and the type its result decodes as. Creating either value performs no networking.

```swift
import SwiftUSDAFoodDataCentralModels

let endpoint = Endpoint<Food>.food(2_346_404)
print(endpoint.path)  // /food/2346404?format=full

let request: FoodRequest<AbridgedFood> = .abridgedFood(2_346_404)
```

To send an endpoint yourself, request ``Endpoint/path`` with ``Endpoint/method`` and, when
present, ``Endpoint/body`` as `application/json`, put your data.gov API key in the `X-Api-Key`
header, and decode the response body with an ordinary `JSONDecoder`. An endpoint never holds the key, and both of its initializers
reject an `api_key` query parameter.

```swift
let food = try JSONDecoder().decode(Food.self, from: body)
```

### Data types and formats

FoodData Central returns a different record shape for each data type. A full-format lookup decodes
as ``Food``, whose case follows the record's `dataType`: ``Food/branded(_:)``,
``Food/foundation(_:)``, ``Food/srLegacy(_:)``, or ``Food/survey(_:)``. A data type without a
modeled shape decodes as ``Food/other(dataType:_:)`` with the whole record kept as ``JSONValue``;
only the abridged Experimental list has been recorded, so a full-format Experimental record is
untested. An abridged lookup decodes as ``AbridgedFood``, one shape for every data type.

``FoodDataType`` is open, so a data type FoodData Central adds later decodes and keeps its exact
spelling. Identifiers, units, dates, and missing values are kept as sent: dates stay strings, and
nothing is converted, defaulted, or filtered. Where FoodData Central sends one field as an integer
in some responses and a string in others, such as `ndbNumber` and an attribute's `value`, it
decodes into one string.

The modeled types keep the fields they declare. A field FoodData Central sends that a modeled type
does not declare, such as a Branded food's `foodUpdateLog`, is not kept; only
``Food/other(dataType:_:)`` and ``InputFood/inputFood`` keep a record whole.

### Validated inputs

``FoodID`` and ``NutrientNumber`` wrap the provider's identifiers. ``NutrientNumbers`` enforces the
specification's limit of one to 25 distinct nutrients per lookup and throws
``FoodDataCentralValidationError`` before any request is described. No response to a request with a
`nutrients` filter has been recorded, so the limit and the filter's results are unverified.

```swift
let macros = try NutrientNumbers([203, 204, 205])
let filtered = Endpoint<AbridgedFood>.abridgedFood(2_346_404, nutrients: macros)
print(filtered.path)  // /food/2346404?format=abridged&nutrients=203,204,205
```

### Several foods at once

``FoodIDs`` holds one to 20 distinct food identifiers, the most FoodData Central accepts on one
`/foods` request, and throws ``FoodDataCentralValidationError`` for an empty, oversized, or
repeated list. The identifiers are sent in the order given; nothing is sorted, removed, or split
across requests.

```swift
let ids = try FoodIDs([167_782, 2_768_188])
let endpoint = Endpoint<[Food]>.foods(ids)
print(endpoint.path)  // /foods?fdcIds=167782,2768188&format=full

let request: FoodRequest<[AbridgedFood]> = .abridgedFoods(ids)
```

The FoodData Central specification says it omits an identifier it does not know, so the result can
be shorter than the list, or empty. It returns the foods in an order it does not document, so match results to
identifiers by each food's `fdcID` rather than by position.

### Food lists

``FoodListQuery`` describes one page of `GET /foods/list`: the data types to list, a one-based page
number, a page size of 1 to 200, and an optional ``FoodSort``. It throws
``FoodDataCentralValidationError`` for a page number below 1 or a page size outside 1 to 200.
``Endpoint/foodList(_:)`` renders the query as the bare array of ``AbridgedFood`` values the service
sends, and ``FoodRequest/foodList(_:)`` describes the same operation as a ``FoodListPage``, the foods
paired with the page number and size that were requested.

```swift
let query = try FoodListQuery(
  dataTypes: [.foundation], pageSize: 2, sort: FoodSort(field: .fdcID, order: .descending))
print(Endpoint.foodList(query).path)
// /foods/list?dataType=Foundation&pageNumber=1&pageSize=2&sortBy=fdcId&sortOrder=desc
```

FoodData Central sends no total or last-page flag, so ``FoodListQuery/next(after:)`` decides what
follows a page: nothing after a page shorter than the page size, and otherwise the same query at the
next page number. That is the SDK's reading, not a guarantee from the service, and a list whose
length is an exact multiple of the page size ends with one empty page. A page that does not answer
its query throws ``FoodPaginationError``. ``FoodSortField`` is open: only `fdcId` is confirmed by
a recorded response, and the specification warns that its two `.keyword` names will change. The
service also refuses pages deeper than an undocumented window; see
``FoodPaginationError/resultWindowExceeded``.

### Food search

``FoodSearchQuery`` describes one page of `POST /foods/search`: search terms, which must hold
something other than whitespace and may use FoodData Central's search operators, plus optional data
types, a brand owner, a sort, a one-based page number, and a page size of 1 to 200. Every parameter
travels in the JSON body, encoded with sorted keys so one query always produces the same bytes.
The brand owner is sent exactly as given and applies only to Branded foods. The ``TradeChannel``
filter and the ``FoodPublicationDate`` range come from the specification, which accepts them only
in a body, and have not been verified against the service.

```swift
let query = try FoodSearchQuery("cheddar cheese", dataTypes: [.branded], pageSize: 25)
let endpoint = Endpoint.foodSearch(query)
print(endpoint.method, endpoint.path)  // post /foods/search
```

A search page decodes as ``FoodSearchResult``, with the totals the service reports and a list of
``SearchResultFood`` values. ``FoodSearchQuery/next(after:)`` continues while the page's
`currentPage` is below its `totalPages` and throws ``FoodPaginationError`` for a page that does
not answer its query. No search response has been recorded: the shapes follow the FoodData Central
specification (version 1.0.1), and where the service is understood to spell a field differently,
such as a nutrient's `value` or a food's `publishedDate`, both spellings are accepted. Neither
spelling is verified. The echoed ``FoodSearchCriteria`` is decoded leniently and never read for
continuation.

### Your own response types

Wrap any validated path in an endpoint with a response type you define, and wrap that endpoint in a
request to execute it with the same client as the built-in factories.

```swift
struct FoodName: Decodable, Sendable {
  let description: String
}

if let endpoint = Endpoint<FoodName>(path: "/food/167782?format=abridged") {
  let request = FoodRequest(endpoint: endpoint)
}
```

### Gateway errors

The api.data.gov gateway answers credential and rate-limit failures with a body that decodes as
``DataGovErrorResponse``, with open codes such as `API_KEY_INVALID` and `OVER_RATE_LIMIT`.

## Topics

### Requests and endpoints

- ``FoodRequest``
- ``Endpoint``
- ``EndpointMethod``

### Food lists

- ``FoodListQuery``
- ``FoodListPage``
- ``FoodPaginationError``
- ``FoodSort``
- ``FoodSortField``
- ``FoodSortOrder``
- ``Endpoint/foodList(_:)``
- ``FoodRequest/foodList(_:)``

### Food search

- ``FoodSearchQuery``
- ``FoodSearchResult``
- ``FoodSearchCriteria``
- ``SearchResultFood``
- ``SearchResultFoodNutrient``
- ``FoodPublicationDate``
- ``TradeChannel``
- ``Endpoint/foodSearch(_:)``
- ``FoodRequest/foodSearch(_:)``

### Identifiers and inputs

- ``FoodDataType``
- ``FoodID``
- ``FoodIDs``
- ``NutrientNumber``
- ``NutrientNumbers``
- ``FoodDataCentralValidationError``

### Full-format foods

- ``Food``
- ``BrandedFood``
- ``FoundationFood``
- ``SRLegacyFood``
- ``SurveyFood``

### Abridged foods

- ``AbridgedFood``
- ``AbridgedFoodNutrient``

### Nutrients

- ``FoodNutrient``
- ``Nutrient``
- ``FoodNutrientDerivation``
- ``FoodNutrientSource``
- ``NutrientAnalysisDetails``
- ``NutrientAcquisitionDetails``
- ``NutrientConversionFactor``
- ``LabelNutrients``

### Categories, attributes, components, and portions

- ``FoodCategory``
- ``FoodAttribute``
- ``FoodAttributeType``
- ``FoodComponent``
- ``FoodPortion``
- ``MeasureUnit``
- ``FoundationInputFood``
- ``SampleFood``

### Survey details

- ``InputFood``
- ``InputFoodRetentionFactor``
- ``WWEIAFoodCategory``

### Gateway errors and raw values

- ``DataGovErrorResponse``
- ``JSONValue``
