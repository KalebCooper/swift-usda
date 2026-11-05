import Foundation

/// A response body recorded from the live FoodData Central API.
///
/// Tests never reach the API. Each case is one body captured once and kept in `Fixtures/`, with the
/// API key removed, so a test decodes exactly what the service sent. Paths are relative to
/// `https://api.nal.usda.gov`.
///
/// ```swift
/// let foods = try JSONDecoder().decode([AbridgedFood].self, from: Fixture.listBranded.data())
/// ```
package enum Fixture: String, CaseIterable, Sendable {
  /// `GET /fdc/v1/foods/list?pageSize=2` with `X-Api-Key: INVALID_FIXTURE_KEY`, the gateway's
  /// `403` body with code `API_KEY_INVALID`.
  case authInvalidKey = "auth-invalid-key"

  /// `GET /fdc/v1/foods/list?pageSize=2` with no key, the gateway's `403` body with code
  /// `API_KEY_MISSING`.
  case authMissingKey = "auth-missing-key"

  /// `GET /fdc/v1/food/2617100?format=abridged`, the abridged Branded food "ALL NATURAL GLUTEN
  /// FREE CHICKEN NUGGETS".
  case foodBrandedAbridged = "food-branded-abridged"

  /// `GET /fdc/v1/food/2617100?format=full`, the full Branded food "ALL NATURAL GLUTEN FREE
  /// CHICKEN NUGGETS", with label nutrients, attributes, and an update log.
  case foodBrandedFull = "food-branded-full"

  /// `GET /fdc/v1/food/2768188?format=abridged`, the abridged Foundation food "Alaska Pollock,
  /// raw", whose NDB number arrives as a string.
  case foodFoundationAbridged = "food-foundation-abridged"

  /// `GET /fdc/v1/food/2768188?format=full`, the full Foundation food "Alaska Pollock, raw", with
  /// nutrient analysis details, sample input foods, and an NDB number sent as an integer.
  case foodFoundationFull = "food-foundation-full"

  /// `GET /fdc/v1/food/167782?format=full`, the full SR Legacy food "Abiyuch, raw", with
  /// portions, attributes, and an NDB number sent as an integer.
  case foodSRLegacyFull = "food-sr-legacy-full"

  /// `GET /fdc/v1/food/2706337?format=full`, the full Survey (FNDDS) food "Abalone", with
  /// portions, attributes, and input foods.
  case foodSurveyFull = "food-survey-full"

  /// `GET /fdc/v1/foods/list?dataType=Foundation&pageNumber=1000&pageSize=200`, the service's
  /// `400` plain-text body for a page past its result window, sent with a JSON content type.
  case listBeyondEnd = "list-beyond-end"

  /// `GET /fdc/v1/foods/list?dataType=Branded&pageSize=2`, two abridged Branded foods.
  case listBranded = "list-branded"

  /// `GET /fdc/v1/foods/list?dataType=Experimental&pageSize=2`, two abridged Experimental foods
  /// with no nutrients; Experimental is absent from the specification's data type list.
  case listExperimental = "list-experimental"

  /// `GET /fdc/v1/foods/list?dataType=Foundation&pageSize=2`, two abridged Foundation foods.
  case listFoundation = "list-foundation"

  /// `GET /fdc/v1/foods/list?dataType=Foundation&pageNumber=0&pageSize=2`, byte for byte the
  /// same body as page 1.
  case listFoundationPage0 = "list-foundation-page-0"

  /// `GET /fdc/v1/foods/list?dataType=Foundation&pageNumber=1&pageSize=2`, the first two abridged
  /// Foundation foods, "Alaska Pollock, raw" and "Almond butter, creamy".
  case listFoundationPage1 = "list-foundation-page-1"

  /// `GET /fdc/v1/foods/list?dataType=Foundation&pageNumber=2&pageSize=2`, the next two abridged
  /// Foundation foods, 2257045 and 1999631.
  case listFoundationPage2 = "list-foundation-page-2"

  /// `GET /fdc/v1/foods/list?dataType=Foundation,SR%20Legacy&pageSize=2`, two abridged SR Legacy
  /// foods listed under the service's default order for the comma-separated filter.
  case listFoundationSRLegacy = "list-foundation-sr-legacy"

  /// `GET /fdc/v1/foods/list?dataType=Foundation&pageSize=2&sortBy=description`, the service's
  /// `400` JSON body rejecting the announced `description` sort name.
  case listSortDescription = "list-sort-description"

  /// `GET /fdc/v1/foods/list?dataType=Foundation&pageSize=2&sortBy=fdcId&sortOrder=desc`, the two
  /// Foundation foods with the highest identifiers, 2779268 then 2779267.
  case listSortFDCIDDescending = "list-sort-fdc-id-desc"

  /// `GET /fdc/v1/foods/list?dataType=SR%20Legacy&pageSize=2`, two abridged SR Legacy foods.
  case listSRLegacy = "list-sr-legacy"

  /// `GET /fdc/v1/foods/list?dataType=Survey%20(FNDDS)&pageSize=2`, two abridged Survey foods,
  /// whose nutrients carry no derivation.
  case listSurvey = "list-survey"

  /// The recorded body.
  ///
  /// - Throws: ``FixtureFailure/missing(name:)`` when the file is not in the bundle, and whatever
  ///   reading it throws.
  package func data() throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: rawValue, withExtension: "json", subdirectory: "Fixtures")
    else {
      throw FixtureFailure.missing(name: rawValue)
    }
    return try Data(contentsOf: url)
  }
}

/// Why a recorded body could not be read.
package enum FixtureFailure: Error, Hashable, Sendable {
  /// No file with this name is in the bundle's `Fixtures/` directory.
  case missing(name: String)
}
