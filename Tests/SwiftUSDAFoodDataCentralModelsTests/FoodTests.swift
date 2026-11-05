import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct FoodTests {
  private func food(_ json: String) throws -> Food {
    try JSONDecoder().decode(Food.self, from: Data(json.utf8))
  }

  private func food(_ fixture: Fixture) throws -> Food {
    try JSONDecoder().decode(Food.self, from: fixture.data())
  }

  @Test("A recorded Foundation food decodes with its nutrients, analyses, and samples")
  func aRecordedFoundationFoodDecodesWithItsNutrientsAnalysesAndSamples() throws {
    let decoded = try food(.foodFoundationFull)
    guard case .foundation(let foundation) = decoded else {
      Issue.record("Expected a Foundation food, got \(decoded)")
      return
    }
    #expect(foundation.fdcID == 2_768_188)
    #expect(foundation.dataType == .foundation)
    #expect(foundation.description == "Alaska Pollock, raw")
    #expect(foundation.ndbNumber == "15266")
    #expect(foundation.foodClass == "FinalFood")
    #expect(foundation.publicationDate == "4/30/2026")
    #expect(foundation.isHistoricalReference == false)
    #expect(
      foundation.foodCategory
        == FoodCategory(
          code: "1500", description: "Finfish and Shellfish Products", id: 15))
    #expect(foundation.foodAttributes == [])
    #expect(foundation.foodPortions == nil)

    let nutrients = try #require(foundation.foodNutrients)
    #expect(nutrients.count == 105)
    let heading = try #require(nutrients.first)
    #expect(heading.id == nil)
    #expect(heading.amount == nil)
    #expect(heading.nutrient?.name == "Proximates")
    #expect(heading.nutrient?.isNutrientLabel == true)
    #expect(heading.nutrient?.indentLevel == 0)
    #expect(heading.nutrient?.numberOfDecimals == 3)
    #expect(heading.nutrient?.shortestName == "Proximates")

    let protein = try #require(nutrients.first { $0.nutrient?.number == "203" })
    #expect(protein.id == 35_089_410)
    #expect(protein.amount == 17.33)
    #expect(protein.dataPoints == 8)
    #expect(protein.min == 16.3)
    #expect(protein.max == 18)
    #expect(protein.median == 17.5)
    #expect(protein.minYearAcquired == 2020)
    #expect(protein.type == "FoodNutrient")
    #expect(protein.foodNutrientDerivation?.code == "A")
    #expect(protein.nutrient?.id == 1003)
    #expect(protein.nutrientAnalysisDetails?.count == 8)
    let analysis = try #require(protein.nutrientAnalysisDetails?.first)
    #expect(analysis.amount == 18)
    #expect(analysis.labMethodDescription == "AOAC 992.23")
    #expect(analysis.labMethodTechnique == "Combustion")
    #expect(analysis.nutrientID == 1003)
    #expect(analysis.subSampleID == 2_768_444)
    #expect(
      analysis.nutrientAcquisitionDetails == [
        NutrientAcquisitionDetails(
          purchaseDate: "7/1/2020", sampleUnitID: 2_768_189, storeCity: "", storeState: "USA")
      ])

    let input = try #require(foundation.inputFoods?.first)
    #expect(input.id == 143_612)
    #expect(input.foodDescription == "Alaska Pollock, raw")
    #expect(
      input.inputFood
        == SampleFood(
          dataType: FoodDataType(rawValue: "Sample"), description: "Alaska Pollock, raw",
          fdcID: 2_768_192, foodClass: "Composite",
          foodGroup: FoodCategory(
            code: "1500", description: "Finfish and Shellfish Products", id: 15),
          publicationDate: "4/30/2026", totalRefuse: 0))

    #expect(
      foundation.nutrientConversionFactors == [
        NutrientConversionFactor(
          carbohydrateValue: 4, fatValue: 9, id: 23_310, name: "Calories From Proximates",
          proteinValue: 4, type: ".CalorieConversionFactor")
      ])
  }

  @Test("A recorded SR Legacy food decodes with its portions and attributes")
  func aRecordedSRLegacyFoodDecodesWithItsPortionsAndAttributes() throws {
    let decoded = try food(.foodSRLegacyFull)
    guard case .srLegacy(let legacy) = decoded else {
      Issue.record("Expected an SR Legacy food, got \(decoded)")
      return
    }
    #expect(legacy.fdcID == 167_782)
    #expect(legacy.dataType == .srLegacy)
    #expect(legacy.description == "Abiyuch, raw")
    #expect(legacy.ndbNumber == "9427")
    #expect(legacy.scientificName == "Crateva religiosa")
    #expect(legacy.publicationDate == "4/1/2019")
    #expect(legacy.foodNutrients?.count == 37)
    let protein = try #require(legacy.foodNutrients?.first { $0.nutrient?.number == "203" })
    #expect(protein.id == 1_304_515)
    #expect(protein.amount == 1.5)
    #expect(protein.dataPoints == 1)

    #expect(
      legacy.foodPortions == [
        FoodPortion(
          amount: 0.5, gramWeight: 114, id: 81_972,
          measureUnit: MeasureUnit(abbreviation: "undetermined", id: 9999, name: "undetermined"),
          modifier: "cup", sequenceNumber: 1)
      ])

    #expect(legacy.foodAttributes?.count == 8)
    #expect(
      legacy.foodAttributes?.first
        == FoodAttribute(
          foodAttributeType: FoodAttributeType(
            description: "Common names associated with a food.", id: 1000, name: "Common Name"),
          id: 2091, sequenceNumber: 0, value: "garlic pear"))
    #expect(legacy.foodAttributes?[1].name == "NCBI Taxon")

    #expect(
      legacy.nutrientConversionFactors?.last
        == NutrientConversionFactor(
          id: 16_533, name: "Protein From Nitrogen", type: ".ProteinConversionFactor", value: 6.25))
  }

  @Test(
    "A recorded full food survives an encode and decode",
    arguments: [
      Fixture.foodBrandedFull, .foodFoundationFull, .foodSRLegacyFull, .foodSurveyFull,
    ])
  func aRecordedFullFoodSurvivesAnEncodeAndDecode(fixture: Fixture) throws {
    let original = try food(fixture)
    let reencoded = try JSONDecoder().decode(Food.self, from: JSONEncoder().encode(original))
    #expect(reencoded == original)
  }

  @Test("An NDB number sent as an integer encodes back as a string")
  func anNDBNumberSentAsAnIntegerEncodesBackAsAString() throws {
    let original = try food(
      #"{"fdcId": 1, "dataType": "SR Legacy", "description": "A", "ndbNumber": 9427}"#)
    let object = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(original))
    guard case .object(let fields) = object else {
      Issue.record("Expected an object, got \(object)")
      return
    }
    #expect(fields["ndbNumber"] == .string("9427"))
  }

  @Test("A record of an unmodeled data type is kept whole")
  func aRecordOfAnUnmodeledDataTypeIsKeptWhole() throws {
    let decoded = try food(#"{"fdcId": 1, "dataType": "Experimental", "extra": [null, true]}"#)
    #expect(
      decoded
        == .other(
          dataType: FoodDataType(rawValue: "Experimental"),
          .object([
            "dataType": .string("Experimental"), "extra": .array([.null, .bool(true)]),
            "fdcId": .number(1),
          ])))
  }

  @Test("An unmodeled record encodes back to the JSON it came from")
  func anUnmodeledRecordEncodesBackToTheJSONItCameFrom() throws {
    let original = try food(#"{"dataType": "Experimental", "fdcId": 1, "note": null}"#)
    let reencoded = try JSONDecoder().decode(
      Food.self, from: JSONEncoder().encode(original))
    #expect(reencoded == original)
  }

  @Test("A record without a data type fails to decode")
  func aRecordWithoutADataTypeFailsToDecode() {
    #expect(throws: DecodingError.self) {
      try food(#"{"fdcId": 1, "description": "No type"}"#)
    }
  }
}
