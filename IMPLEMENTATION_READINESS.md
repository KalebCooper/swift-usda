# Implementation readiness

`SwiftUSDAFoodDataCentralModels` and `SwiftUSDAFoodDataCentral` are implemented and the hosted workflows are enabled. No version is released and no remote exists. The items below record what is done and which gates remain.

## Activation record

Done in the first slice and the changes after it:

- Manifest, source, fixtures, and tests for food lookup by identifier, multi-food lookup, the paged list, and search.
- Both DocC catalogs, `.spi.yml` listing the models target first, and README, CHANGELOG, and CONTRIBUTING.
- The demo, `Examples/SwiftUSDAFoodDataCentralDemo/SwiftUSDAFoodDataCentralDemo.xcodeproj`.
- The source gate with no argument; the `--scaffold` mode and its script are gone, and the not-ready guards are removed.
- CI: the source job, lint widened to `Sources Tests Examples/SwiftUSDAFoodDataCentralDemo/SwiftUSDAFoodDataCentralDemo`, and the Linux, Android, and Apple lanes enabled, in that order, with the Release demo build on the Apple lane.
- Documentation: the `docs.yml` build and Pages deploy enabled, with deployment limited to `main`.

The hosted lanes are configured and have not run. Nothing has been pushed.

## Local gates before the first push

- `bash Scripts/verify.sh` and `bash Scripts/verify.sh --self-test` exit 0.
- `swift format lint --strict --recursive Sources Tests Examples/SwiftUSDAFoodDataCentralDemo/SwiftUSDAFoodDataCentralDemo` reports no findings.
- Apple build and tests pass through the Xcode MCP tools with the generated `swift-usda-Package` scheme on an iOS 27 simulator.
- `bash Scripts/linux-test.sh` passes with `HTTPPortable` and under the default trait set, and restores `Package.resolved`.
- Both DocC catalogs build with zero warnings, models first, through `Scripts/build-docs.sh`.
- The demo builds and runs with the package's own workspace closed.

## Pending hosted gates

- First hosted run of every lane on `main`: Linux (trait on, then default traits), Android emulator (which runs only in CI), iOS simulator with the Release demo build, lint, the source gate, and the documentation build.
- Each provisional `timeout-minutes` in `ci.yml` and `docs.yml` set from that job's slowest green run, rounded up to five minutes and tripled.
- Confirm the Android action pin and `swift-version` still match swifty-networking and the other family packages on the day of the first run.
- GitHub Pages enabled for the repository and the first deploy from `main`; Swift Package Index registration.
- Remote creation, push, tags, and releases, which require owner authorization.

`bash Scripts/verify.sh` is the source gate. A passing gate is not a build, test, or portability result.
