# swift-usda

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Swift package infrastructure for USDA FoodData Central.

## Status

Infrastructure only. No government API, library products, source targets, fixtures, or tests are implemented. The package is not ready for application use and has no release or remote repository configured.

Future coverage is FoodData Central food search, food details, nutrients, portions, and branded and generic foods. FoodData Central requires a data.gov API key and publishes no update schedule, so the API guarantees no data freshness. Coverage, ordering, and pagination behavior must be verified when implemented.

## Usage

Run `bash Scripts/verify.sh --scaffold` to validate infrastructure. The default verification command deliberately fails until service source exists. See [implementation readiness](IMPLEMENTATION_READINESS.md) for deferred gates.

## Example

No API example is available because no API is implemented.

## Products

| Product | Status |
| --- | --- |
| None | Products are added only with working service source. |

## Requirements

The manifest declares Swift tools 6.2, Swift 6 language mode, and iOS, macOS, tvOS, visionOS, and watchOS 26. Infrastructure verification needs Bash, Python 3, Git, and Swift with swift-format. No Apple, Linux, or Android library compatibility has been established yet.

## Installation

No installable library or published version exists yet. Dependency pins and the portable transport trait will be added with the first implemented slice.

## License

MIT. See [LICENSE](LICENSE). FoodData Central data is in the public domain under CC0 1.0, and FoodData Central asks to be credited as its source: [USDA FoodData Central](https://fdc.nal.usda.gov/).
