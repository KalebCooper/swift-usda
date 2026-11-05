import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct BrandedFoodTests {
  private func food(_ data: Data) throws -> Food {
    try JSONDecoder().decode(Food.self, from: data)
  }

  @Test("A recorded Branded food decodes with its label data and attributes")
  func aRecordedBrandedFoodDecodesWithItsLabelDataAndAttributes() throws {
    let decoded = try food(Fixture.foodBrandedFull.data())
    guard case .branded(let branded) = decoded else {
      Issue.record("Expected a Branded food, got \(decoded)")
      return
    }
    #expect(branded.fdcID == 2_617_100)
    #expect(branded.dataType == .branded)
    #expect(branded.description == " ALL NATURAL GLUTEN FREE CHICKEN NUGGETS")
    #expect(branded.availableDate == "6/23/2023")
    #expect(branded.brandedFoodCategory == "Frozen Poultry, Chicken & Turkey")
    #expect(branded.brandName == "GOLDEN PLATTER")
    #expect(branded.brandOwner == "Golden Platter Foods Inc.")
    #expect(branded.dataSource == "LI")
    #expect(branded.discontinuedDate == "")
    #expect(branded.gtinUpc == "0099447210127")
    #expect(branded.householdServingFullText == "5 nuggets (85g)")
    #expect(branded.marketCountry == "United States")
    #expect(branded.modifiedDate == "6/23/2023")
    #expect(branded.packageWeight == "24 oz")
    #expect(branded.publicationDate == "8/31/2023")
    #expect(branded.servingSize == 85)
    #expect(branded.servingSizeUnit == "GRM")
    #expect(branded.shortDescription == "")
    #expect(branded.gpcClassCode == nil)
    #expect(branded.preparationStateCode == nil)
    #expect(branded.tradeChannel == nil)

    #expect(branded.foodNutrients?.count == 14)
    let protein = try #require(branded.foodNutrients?.first { $0.nutrient?.number == "203" })
    #expect(protein.id == 32_701_493)
    #expect(protein.amount == 18.82)
    #expect(protein.foodNutrientDerivation?.code == "LCCS")
    #expect(protein.foodNutrientDerivation?.foodNutrientSource?.code == "12")

    let label = try #require(branded.labelNutrients)
    #expect(label.calories == LabelNutrients.Value(value: 165))
    #expect(label.protein == LabelNutrients.Value(value: 16))
    #expect(label.sodium == LabelNutrients.Value(value: 340))
    #expect(label.iron == LabelNutrients.Value(value: 0.722))
    #expect(label.potassium == nil)

    let updateLog = FoodAttributeType(
      description: "Changes that were made to this food", id: 998, name: "Update Log")
    #expect(
      branded.foodAttributes == [
        FoodAttribute(
          foodAttributeType: updateLog, id: 3_140_100, name: "Nutrient Added", value: "5"),
        FoodAttribute(
          foodAttributeType: updateLog, id: 3_140_101, name: "Nutrient Removed", value: "6"),
      ])
  }

  @Test("Specification-only Branded fields decode when present")
  func specificationOnlyBrandedFieldsDecodeWhenPresent() throws {
    let decoded = try food(
      Data(
        """
        {"fdcId": 1, "dataType": "Branded", "description": "A", "gpcClassCode": 50161800,
         "preparationStateCode": "UNPREPARED", "tradeChannel": ["GROCERY", "NEW_CHANNEL"],
         "labelNutrients": {"potassium": {"value": null}}}
        """.utf8))
    guard case .branded(let branded) = decoded else {
      Issue.record("Expected a Branded food, got \(decoded)")
      return
    }
    #expect(branded.gpcClassCode == 50_161_800)
    #expect(branded.preparationStateCode == "UNPREPARED")
    #expect(branded.tradeChannel == ["GROCERY", "NEW_CHANNEL"])
    #expect(branded.labelNutrients?.potassium == LabelNutrients.Value(value: nil))
  }
}
