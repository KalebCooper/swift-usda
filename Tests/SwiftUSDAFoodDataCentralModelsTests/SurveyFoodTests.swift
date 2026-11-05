import Foundation
import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct SurveyFoodTests {
  private func food(_ data: Data) throws -> Food {
    try JSONDecoder().decode(Food.self, from: data)
  }

  @Test("A recorded Survey food decodes with its nutrients, portions, and input foods")
  func aRecordedSurveyFoodDecodesWithItsNutrientsPortionsAndInputFoods() throws {
    let decoded = try food(Fixture.foodSurveyFull.data())
    guard case .survey(let survey) = decoded else {
      Issue.record("Expected a Survey food, got \(decoded)")
      return
    }
    #expect(survey.fdcID == 2_706_337)
    #expect(survey.dataType == .survey)
    #expect(survey.description == "Abalone")
    #expect(survey.foodClass == "Survey")
    #expect(survey.foodCode == "26301110")
    #expect(survey.startDate == "1/1/2021")
    #expect(survey.endDate == "12/31/2023")
    #expect(survey.publicationDate == "10/31/2024")
    #expect(
      survey.wweiaFoodCategory
        == WWEIAFoodCategory(
          wweiaFoodCategoryCode: 3_300_222, wweiaFoodCategoryDescription: "Shellfish"))

    #expect(survey.foodNutrients?.count == 65)
    let protein = try #require(survey.foodNutrients?.first { $0.nutrient?.number == "203" })
    #expect(protein.id == 34_198_104)
    #expect(protein.amount == 21.2)
    #expect(protein.foodNutrientDerivation == nil)

    #expect(survey.foodPortions?.count == 2)
    #expect(
      survey.foodPortions?.first
        == FoodPortion(
          gramWeight: 85, id: 294_970,
          measureUnit: MeasureUnit(abbreviation: "undetermined", id: 9999, name: "undetermined"),
          modifier: "90000", portionDescription: "Quantity not specified", sequenceNumber: 2))

    #expect(
      survey.foodAttributes?.first
        == FoodAttribute(
          foodAttributeType: FoodAttributeType(
            description: "Adjustments made to foods, including moisture changes", id: 1002,
            name: "Adjustments"),
          id: 3_319_777, value: "Moisture change: -23%"))

    #expect(survey.inputFoods?.count == 3)
    #expect(
      survey.inputFoods?.first
        == InputFood(
          amount: 4, foodDescription: "Vegetable oil, NFS", id: 126_526,
          ingredientCode: 82_101_000, ingredientDescription: "Vegetable oil, NFS",
          ingredientWeight: 4, portionCode: "0", portionDescription: "NONE", retentionCode: 0,
          sequenceNumber: 2, unit: "GM"))
  }

  @Test("A sparse nested input food record is kept whole without failing the Survey food")
  func aSparseNestedInputFoodRecordIsKeptWholeWithoutFailingTheSurveyFood() throws {
    let decoded = try food(
      Data(
        #"""
        {"fdcId": 1, "dataType": "Survey (FNDDS)", "description": "Recipe",
         "inputFoods": [{"id": 2, "inputFood": {"datatype": "Survey (FNDDS)", "fdcId": 3}}]}
        """#.utf8))
    guard case .survey(let survey) = decoded else {
      Issue.record("Expected a Survey food, got \(decoded)")
      return
    }
    #expect(
      survey.inputFoods?.first?.inputFood
        == .object(["datatype": .string("Survey (FNDDS)"), "fdcId": .number(3)]))
  }
}
