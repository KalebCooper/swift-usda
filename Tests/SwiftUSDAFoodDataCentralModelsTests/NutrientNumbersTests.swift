import SwiftUSDAFoodDataCentralModels
import SwiftUSDAFoodDataCentralTestSupport
import Testing

@Suite(.timeLimit(.minutes(suiteTimeLimitMinutes)))
struct NutrientNumbersTests {
  @Test("An empty nutrient list is rejected with its count")
  func anEmptyNutrientListIsRejectedWithItsCount() {
    #expect(throws: FoodDataCentralValidationError.nutrientNumberCount(0)) {
      try NutrientNumbers([])
    }
  }

  @Test("Twenty-six nutrient numbers are rejected with their count")
  func twentySixNutrientNumbersAreRejectedWithTheirCount() {
    #expect(throws: FoodDataCentralValidationError.nutrientNumberCount(26)) {
      try NutrientNumbers((1...26).map { NutrientNumber($0) })
    }
  }

  @Test("A repeated nutrient number is rejected by name")
  func aRepeatedNutrientNumberIsRejectedByName() {
    #expect(throws: FoodDataCentralValidationError.duplicateNutrientNumber(204)) {
      try NutrientNumbers([203, 204, 205, 204])
    }
  }

  @Test("Twenty-five distinct numbers are kept in the order given")
  func twentyFiveDistinctNumbersAreKeptInTheOrderGiven() throws {
    let numbers = (1...25).reversed().map { NutrientNumber($0) }
    #expect(try NutrientNumbers(numbers).numbers == numbers)
  }
}
