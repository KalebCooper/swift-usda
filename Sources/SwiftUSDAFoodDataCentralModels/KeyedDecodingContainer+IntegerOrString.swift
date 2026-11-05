extension KeyedDecodingContainer {
  // FoodData Central sends some codes as a JSON string in one response and as a JSON integer in
  // another: `ndbNumber` is `"15266"` in abridged and list records and `15266` in full records.
  // Both decode into the one string, so a value reads the same whichever endpoint returned it.
  func decodeIntegerOrStringIfPresent(forKey key: Key) throws -> String? {
    guard contains(key), try !decodeNil(forKey: key) else { return nil }
    if let integer = try? decode(Int.self, forKey: key) { return String(integer) }
    return try decode(String.self, forKey: key)
  }
}
