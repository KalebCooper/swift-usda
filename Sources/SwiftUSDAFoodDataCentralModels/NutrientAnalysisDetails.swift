/// One laboratory analysis behind a nutrient amount.
///
/// ```swift
/// for analysis in nutrient.nutrientAnalysisDetails ?? [] {
///   print(analysis.amount, analysis.labMethodDescription)
/// }
/// ```
public struct NutrientAnalysisDetails: Codable, Hashable, Sendable {
  /// The analyzed amount.
  public var amount: Double?
  /// The laboratory method's description.
  public var labMethodDescription: String?
  /// A link describing the method, kept as the provider's string.
  public var labMethodLink: String?
  /// The method's original description.
  public var labMethodOriginalDescription: String?
  /// The analytical technique.
  public var labMethodTechnique: String?
  /// Where the analyzed samples were acquired.
  public var nutrientAcquisitionDetails: [NutrientAcquisitionDetails]?
  /// The analyzed nutrient's ID.
  public var nutrientID: Int?
  /// The analyzed subsample's identifier.
  public var subSampleID: Int?

  /// Creates analysis details.
  /// - Parameters:
  ///   - amount: The analyzed amount.
  ///   - labMethodDescription: The laboratory method's description.
  ///   - labMethodLink: A link describing the method.
  ///   - labMethodOriginalDescription: The method's original description.
  ///   - labMethodTechnique: The analytical technique.
  ///   - nutrientAcquisitionDetails: Where the analyzed samples were acquired.
  ///   - nutrientID: The analyzed nutrient's ID.
  ///   - subSampleID: The analyzed subsample's identifier.
  public init(
    amount: Double? = nil,
    labMethodDescription: String? = nil,
    labMethodLink: String? = nil,
    labMethodOriginalDescription: String? = nil,
    labMethodTechnique: String? = nil,
    nutrientAcquisitionDetails: [NutrientAcquisitionDetails]? = nil,
    nutrientID: Int? = nil,
    subSampleID: Int? = nil
  ) {
    self.amount = amount
    self.labMethodDescription = labMethodDescription
    self.labMethodLink = labMethodLink
    self.labMethodOriginalDescription = labMethodOriginalDescription
    self.labMethodTechnique = labMethodTechnique
    self.nutrientAcquisitionDetails = nutrientAcquisitionDetails
    self.nutrientID = nutrientID
    self.subSampleID = subSampleID
  }

  enum CodingKeys: String, CodingKey {
    case amount
    case labMethodDescription
    case labMethodLink
    case labMethodOriginalDescription
    case labMethodTechnique
    case nutrientAcquisitionDetails
    case nutrientID = "nutrientId"
    case subSampleID = "subSampleId"
  }
}
