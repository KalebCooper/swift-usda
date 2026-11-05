# Implementation readiness

The first FoodData Central slice, food lookup by identifier in the full and abridged formats, is implemented in `SwiftUSDAFoodDataCentralModels` and `SwiftUSDAFoodDataCentral`. No version is released. The items below record which activation steps are complete and which gates remain.

## First service slice

The product pair is `SwiftUSDAFoodDataCentralModels` and `SwiftUSDAFoodDataCentral`. The first slice is one FoodData Central endpoint group end to end, before coverage widens.

Before writing code, verify the current FDC API guide and OpenAPI specification for that endpoint group: base URL, `X-Api-Key` header authentication, rate limits and their headers, parameters and their bounds, response shapes per data type, and data.gov gateway error bodies. Where the specification is silent, establish behavior from recorded responses: whether `pageNumber` is zero- or one-based, the terminal-page rule for list responses that carry no totals, and the spelling of the Survey data type key.

## Activation checklist

Complete these in the change that adds the first slice:

1. Manifest: declare both products, the models, SDK, and test support targets, and both test targets, alphabetically and each with the shared `swiftSettings`. Add the `HTTPPortable` trait forwarded to swifty-networking, swifty-networking `from: "1.1.0"`, and swift-http-types `from: "1.6.0"`. Condition the SDK's `HTTPPortable` edge on the trait and its `HTTPURLSession` edge on Apple platforms. Track the trait-on `Package.resolved` superset.
2. Source: models, validated inputs, endpoints, the domain request type and its resolution, `FoodDataCentralClient`, `FoodDataCentralConfiguration` with a required API key, and `FoodDataCentralError`. Compile the everyday method, contextual factory, unannotated stored request, consumer-defined factory, and consumer-defined single-endpoint response call sites before settling the public shape.
3. Fixtures and tests: record each body once with the package `User-Agent` and the API key removed, add a documented `Fixture` case per recording, and cover the slice with Swift Testing suites that use the mock transport and the shared suite time limit.
4. [x] Documentation: one DocC catalog per product, `.spi.yml` listing the models target first, and README, CHANGELOG, and CONTRIBUTING describing exactly what works.
5. Demo: `Examples/SwiftUSDAFoodDataCentralDemo/SwiftUSDAFoodDataCentralDemo.xcodeproj` with bundle identifier `dev.cooperlabs.SwiftUSDAFoodDataCentralDemo`.
6. [x] Gate: make `Scripts/verify.sh` run the source gate with no argument and drop the `--scaffold` mode and `Scripts/verify-scaffold.py`. Remove the not-ready guards from `Scripts/verify-source.sh`, `Scripts/linux-test.sh`, and `Scripts/build-docs.sh`.
7. CI: [x] replace the `scaffold` job with a source job that runs `bash Scripts/verify.sh` and `bash Scripts/verify.sh --self-test`; [x] widen the lint lane to `Sources Tests`; [ ] add `Examples/SwiftUSDAFoodDataCentralDemo/SwiftUSDAFoodDataCentralDemo` to the lint lane; [ ] enable the Linux, Android, and Apple lanes; [ ] enable the documentation build, with deployment limited to `main`.

## Local gates before activation

- `bash Scripts/verify.sh` and `bash Scripts/verify.sh --self-test` exit 0.
- `swift format lint --strict --recursive Sources Tests` reports no findings.
- Apple build and tests pass through the Xcode MCP tools with the generated `swift-usda-Package` scheme on an iOS 27 simulator.
- `bash Scripts/linux-test.sh` passes with `HTTPPortable` and under the default trait set, and restores `Package.resolved`.
- Both DocC catalogs build with zero warnings, models first, through `Scripts/build-docs.sh`.
- The demo builds and runs with the package's own workspace closed.

## Pending hosted gates

- Android emulator suite, which runs only in CI.
- Hosted Linux, Apple, lint, and documentation runs on `main`, after which each provisional `timeout-minutes` is set from its slowest green run.
- GitHub Pages and Swift Package Index publication.
- Remote creation, push, tags, and releases, which require owner authorization.

`bash Scripts/verify.sh` is the source gate. A passing gate is not a build, test, or portability result.
