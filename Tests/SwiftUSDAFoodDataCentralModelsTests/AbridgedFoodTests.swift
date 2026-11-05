import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct AbridgedFoodTests {
  private func foods(_ fixture: Fixture) throws -> [AbridgedFood] {
    try JSONDecoder().decode([AbridgedFood].self, from: fixture.data())
  }

  private func food(_ fixture: Fixture) throws -> AbridgedFood {
    try JSONDecoder().decode(AbridgedFood.self, from: fixture.data())
  }

  @Test("An abridged Foundation food by identifier keeps its NDB number as a string")
  func anAbridgedFoundationFoodByIdentifierKeepsItsNDBNumberAsAString() throws {
    let food = try food(.foodFoundationAbridged)
    #expect(food.fdcID == 2_768_188)
    #expect(food.dataType == .foundation)
    #expect(food.description == "Alaska Pollock, raw")
    #expect(food.ndbNumber == "15266")
    #expect(food.publicationDate == "2026-04-30")
    #expect(food.brandOwner == nil)
    #expect(food.foodNutrients.count == 99)
    #expect(
      food.foodNutrients.first { $0.number == "203" }
        == AbridgedFoodNutrient(
          amount: 17.3, derivationCode: "A", derivationDescription: "Analytical",
          name: "Protein", number: "203", unitName: "G"))
  }

  @Test("An abridged Branded food by identifier keeps its brand owner and barcode")
  func anAbridgedBrandedFoodByIdentifierKeepsItsBrandOwnerAndBarcode() throws {
    let food = try food(.foodBrandedAbridged)
    #expect(food.fdcID == 2_617_100)
    #expect(food.dataType == .branded)
    #expect(food.description == " ALL NATURAL GLUTEN FREE CHICKEN NUGGETS")
    #expect(food.brandOwner == "Golden Platter Foods Inc.")
    #expect(food.gtinUpc == "0099447210127")
    #expect(food.ndbNumber == nil)
    #expect(food.publicationDate == "2023-08-31")
    #expect(food.foodNutrients.count == 14)
    #expect(
      food.foodNutrients.first { $0.number == "203" }
        == AbridgedFoodNutrient(
          amount: 18.8, derivationCode: "LCCS",
          derivationDescription: "Calculated from value per serving size measure",
          name: "Protein", number: "203", unitName: "G"))
  }

  @Test(
    "An abridged food by identifier survives an encode and decode",
    arguments: [Fixture.foodBrandedAbridged, .foodFoundationAbridged])
  func anAbridgedFoodByIdentifierSurvivesAnEncodeAndDecode(fixture: Fixture) throws {
    let original = try food(fixture)
    let reencoded = try JSONDecoder().decode(
      AbridgedFood.self, from: JSONEncoder().encode(original))
    #expect(reencoded == original)
  }

  @Test("An Experimental list food keeps its unlisted data type and empty nutrients")
  func anExperimentalListFoodKeepsItsUnlistedDataTypeAndEmptyNutrients() throws {
    let foods = try foods(.listExperimental)
    #expect(foods.map(\.fdcID) == [2_715_733, 2_715_727])
    #expect(foods.allSatisfy { $0.dataType == FoodDataType(rawValue: "Experimental") })
    #expect(foods.allSatisfy { $0.foodNutrients.isEmpty })
    #expect(foods[0].publicationDate == "2024-10-31")
  }

  @Test("A Branded list food keeps its brand owner, barcode zeros, and leading space")
  func aBrandedListFoodKeepsItsBrandOwnerBarcodeZerosAndLeadingSpace() throws {
    let food = try #require(try foods(.listBranded).first)
    #expect(food.fdcID == 2_617_100)
    #expect(food.dataType == .branded)
    #expect(food.description == " ALL NATURAL GLUTEN FREE CHICKEN NUGGETS")
    #expect(food.brandOwner == "Golden Platter Foods Inc.")
    #expect(food.gtinUpc == "0099447210127")
    #expect(food.ndbNumber == nil)
    #expect(food.foodCode == nil)
    #expect(food.publicationDate == "2023-08-31")
    #expect(food.foodNutrients.count == 14)
    let protein = try #require(food.foodNutrients.first)
    #expect(protein.amount == 18.8)
    #expect(protein.derivationCode == "LCCS")
    #expect(protein.derivationDescription == "Calculated from value per serving size measure")
    #expect(protein.name == "Protein")
    #expect(protein.number == "203")
    #expect(protein.unitName == "G")
  }

  @Test("A Foundation list food keeps its NDB number as a string")
  func aFoundationListFoodKeepsItsNDBNumberAsAString() throws {
    let food = try #require(try foods(.listFoundation).first)
    #expect(food.fdcID == 2_768_188)
    #expect(food.dataType == .foundation)
    #expect(food.description == "Alaska Pollock, raw")
    #expect(food.ndbNumber == "15266")
    #expect(food.brandOwner == nil)
    #expect(food.foodNutrients.count == 99)
    #expect(food.foodNutrients.first?.amount == 0.00659)
    #expect(food.foodNutrients.first?.number == "855")
  }

  @Test("An SR Legacy list nutrient without a derivation decodes with none")
  func anSRLegacyListNutrientWithoutADerivationDecodesWithNone() throws {
    let foods = try foods(.listSRLegacy)
    #expect(foods.map(\.fdcID) == [167_782, 171_687])
    #expect(foods.allSatisfy { $0.dataType == .srLegacy })
    #expect(foods[0].ndbNumber == "9427")
    let energy = try #require(foods[1].foodNutrients.first)
    #expect(energy.amount == 96)
    #expect(energy.derivationCode == nil)
    #expect(energy.derivationDescription == nil)
    #expect(energy.name == "Energy")
    #expect(energy.number == "268")
    #expect(energy.unitName == "kJ")
  }

  @Test("A Survey list food keeps its food code and has no derivations")
  func aSurveyListFoodKeepsItsFoodCodeAndHasNoDerivations() throws {
    let foods = try foods(.listSurvey)
    let food = try #require(foods.first)
    #expect(food.fdcID == 2_706_337)
    #expect(food.dataType == .survey)
    #expect(food.dataType.rawValue == "Survey (FNDDS)")
    #expect(food.foodCode == "26301110")
    #expect(food.ndbNumber == nil)
    #expect(food.foodNutrients.count == 65)
    #expect(foods.flatMap(\.foodNutrients).allSatisfy { $0.derivationCode == nil })
  }
}
