# Contributing

Run `bash Scripts/verify.sh` before every commit; it must exit 0. It checks source boundaries and
imports, forbidden APIs, test conventions, workflow timeouts, user-facing text, and strict
formatting. After changing a script under `Scripts/`, also run `bash Scripts/verify.sh --self-test`,
and add a planted violation to the self-test for every new check.

Build and run the tests for the generated `swift-usda-Package` scheme on an iOS simulator, run
`bash Scripts/linux-test.sh` before pushing anything that reaches Linux, and build both DocC catalogs
with zero warnings:

```sh
bash Scripts/build-docs.sh /path/to/Debug-iphonesimulator /tmp/swift-usda-docs
```

Widen coverage one complete FoodData Central slice at a time: models and endpoints, the client
method, recorded fixtures, Swift Testing suites, consumer call-site examples, DocC, README, and
changelog together. Preserve FDC identifiers, units, nulls, unknown values, and data-type
distinctions.

Tests never reach the live API. Record each response body once into
`Sources/SwiftUSDAFoodDataCentralTestSupport/Fixtures/`, add a documented `Fixture` case naming the
exact path and query, and read it with `data()`. Send the key only in the `X-Api-Key` header while
recording, and never commit a data.gov API key in a fixture, test, or document; data.gov deactivates
keys found in public repositories.

Use Swift 6, the manifest's shared strict settings, alphabetical declarations within logical groups,
and strict formatting. Models have no networking dependencies. Use Xcode MCP tools for Apple project
operations and generated package schemes.

Before pushing, run the local gates listed in
[implementation readiness](IMPLEMENTATION_READINESS.md). Each CI timeout is the job's slowest green
run on `main`, rounded up to five minutes and tripled. Use focused Conventional Commits; publishing requires owner authorization.
