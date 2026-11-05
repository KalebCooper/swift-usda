import SwiftUI
import SwiftUSDAFoodDataCentral
import SwiftUSDAFoodDataCentralModels

/// The full record for one food, in the shape its data type defines.
struct FoodDetailView: View {
  let client: FoodDataCentralClient
  let id: FoodID

  @State private var food: Food?
  @State private var message = "Loading food."

  var body: some View {
    List {
      if let food {
        FoodRecordSections(food: food)
      } else {
        Text(message)
          .accessibilityIdentifier("detailStatus")
      }
    }
    .navigationTitle("FDC ID \(id.rawValue)")
    .navigationBarTitleDisplayMode(.inline)
    .task(id: id) {
      message = "Loading food."
      do throws(FoodDataCentralError) {
        food = try await client.food(id)
      } catch {
        message = ErrorDescription.text(for: error)
      }
    }
  }
}

/// The sections for each `Food` case.
struct FoodRecordSections: View {
  let food: Food

  var body: some View {
    switch food {
    case .branded(let branded):
      Section("Branded") {
        LabeledValue("Description", branded.description)
        LabeledValue("Brand owner", branded.brandOwner)
        LabeledValue("Brand name", branded.brandName)
        LabeledValue("Category", branded.brandedFoodCategory)
        LabeledValue("GTIN/UPC", branded.gtinUpc)
        LabeledValue("Serving size", servingSize(branded))
        LabeledValue("Household serving", branded.householdServingFullText)
        LabeledValue("Ingredients", branded.ingredients)
        LabeledValue("Published", branded.publicationDate)
      }
      if let label = branded.labelNutrients {
        LabelNutrientsSection(label: label)
      }
      NutrientsSection(nutrients: branded.foodNutrients)
    case .foundation(let foundation):
      Section("Foundation") {
        LabeledValue("Description", foundation.description)
        LabeledValue("Category", foundation.foodCategory?.description)
        LabeledValue("NDB number", foundation.ndbNumber)
        LabeledValue("Scientific name", foundation.scientificName)
        LabeledValue("Published", foundation.publicationDate)
      }
      NutrientsSection(nutrients: foundation.foodNutrients)
      PortionsSection(portions: foundation.foodPortions)
    case .other(let dataType, let record):
      Section(dataType.rawValue) {
        Text("This data type has no typed model, so the record is kept whole as JSON.")
        if case .object(let fields) = record {
          LabeledValue("Fields", fields.keys.sorted().joined(separator: ", "))
        }
      }
    case .srLegacy(let legacy):
      Section("SR Legacy") {
        LabeledValue("Description", legacy.description)
        LabeledValue("Category", legacy.foodCategory?.description)
        LabeledValue("NDB number", legacy.ndbNumber)
        LabeledValue("Scientific name", legacy.scientificName)
        LabeledValue("Published", legacy.publicationDate)
      }
      NutrientsSection(nutrients: legacy.foodNutrients)
      PortionsSection(portions: legacy.foodPortions)
    case .survey(let survey):
      Section("Survey (FNDDS)") {
        LabeledValue("Description", survey.description)
        LabeledValue("Food code", survey.foodCode)
        LabeledValue("WWEIA category", survey.wweiaFoodCategory?.wweiaFoodCategoryDescription)
        LabeledValue("Survey period", surveyPeriod(survey))
        LabeledValue("Published", survey.publicationDate)
      }
      NutrientsSection(nutrients: survey.foodNutrients)
      PortionsSection(portions: survey.foodPortions)
    }
  }

  private func servingSize(_ food: BrandedFood) -> String? {
    guard let size = food.servingSize else { return nil }
    return [size.formatted(), food.servingSizeUnit].compactMap { $0 }.joined(separator: " ")
  }

  private func surveyPeriod(_ food: SurveyFood) -> String? {
    guard food.startDate != nil || food.endDate != nil else { return nil }
    return "\(food.startDate ?? "?") to \(food.endDate ?? "?")"
  }
}

/// A row that shows a value, or nothing when FoodData Central sent none.
struct LabeledValue: View {
  let title: String
  let value: String?

  init(_ title: String, _ value: String?) {
    self.title = title
    self.value = value
  }

  var body: some View {
    if let value, !value.isEmpty {
      LabeledContent(title) {
        Text(value)
          .multilineTextAlignment(.trailing)
      }
    }
  }
}

/// Nutrient amounts in the units FoodData Central reports, unconverted.
struct NutrientsSection: View {
  let nutrients: [FoodNutrient]?

  var body: some View {
    Section("Nutrients") {
      if let nutrients, !nutrients.isEmpty {
        // Offsets: nutrient identifiers are optional and not documented as unique.
        ForEach(Array(nutrients.enumerated()), id: \.offset) { _, nutrient in
          LabeledContent {
            Text(amount(nutrient))
          } label: {
            Text(nutrient.nutrient?.name ?? "Unnamed nutrient")
            if let number = nutrient.nutrient?.number {
              Text("Number \(number)")
            }
          }
        }
      } else {
        Text("No nutrients in this record.")
      }
    }
  }

  private func amount(_ nutrient: FoodNutrient) -> String {
    guard let amount = nutrient.amount else { return "No amount" }
    return [amount.formatted(), nutrient.nutrient?.unitName].compactMap { $0 }
      .joined(separator: " ")
  }
}

/// Portions with their gram weights as recorded.
struct PortionsSection: View {
  let portions: [FoodPortion]?

  var body: some View {
    Section("Portions") {
      if let portions, !portions.isEmpty {
        ForEach(Array(portions.enumerated()), id: \.offset) { _, portion in
          LabeledContent(name(portion)) {
            Text(portion.gramWeight.map { "\($0.formatted()) g" } ?? "No weight")
          }
        }
      } else {
        Text("No portions in this record.")
      }
    }
  }

  private func name(_ portion: FoodPortion) -> String {
    let parts = [
      portion.amount?.formatted(), portion.measureUnit?.name, portion.modifier,
      portion.portionDescription,
    ]
    .compactMap { $0 }
    .filter { !$0.isEmpty }
    return parts.isEmpty ? "Portion" : parts.joined(separator: " ")
  }
}

/// The per-serving label values a Branded record carries.
struct LabelNutrientsSection: View {
  let label: LabelNutrients

  var body: some View {
    Section("Label nutrients, per serving") {
      LabeledValue("Calories", text(label.calories))
      LabeledValue("Fat", text(label.fat))
      LabeledValue("Saturated fat", text(label.saturatedFat))
      LabeledValue("Trans fat", text(label.transFat))
      LabeledValue("Cholesterol", text(label.cholesterol))
      LabeledValue("Sodium", text(label.sodium))
      LabeledValue("Carbohydrates", text(label.carbohydrates))
      LabeledValue("Fiber", text(label.fiber))
      LabeledValue("Sugars", text(label.sugars))
      LabeledValue("Protein", text(label.protein))
      LabeledValue("Calcium", text(label.calcium))
      LabeledValue("Iron", text(label.iron))
      LabeledValue("Potassium", text(label.potassium))
    }
  }

  private func text(_ value: LabelNutrients.Value?) -> String? {
    value?.value?.formatted()
  }
}
