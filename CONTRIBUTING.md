# Contributing

The repository currently contains infrastructure only. Run `bash Scripts/verify.sh --scaffold` and `bash Scripts/verify.sh --self-test` before committing infrastructure changes. `bash Scripts/verify.sh` is the full source gate and intentionally fails in this state.

The first change with source is one complete FoodData Central slice: portable models and endpoints and their independent client, together with recorded fixtures, Swift Testing suites, consumer call-site examples, DocC catalogs, a demo, and an honest README and changelog update. Preserve FDC identifiers, units, nulls, unknown values, and data-type distinctions.

Never commit a data.gov API key. Strip the `api_key` query parameter from every recorded fixture and its documentation; data.gov deactivates keys found in public repositories.

Use Swift 6, the manifest's shared strict settings, alphabetical declarations within logical groups, and strict formatting. Models have no networking dependencies. Tests use recorded provider data rather than live requests. Use Xcode MCP tools for Apple project operations and generated package schemes.

Before publishing source, complete the Apple, Linux default and portable, Android, documentation, and demo gates listed in [implementation readiness](IMPLEMENTATION_READINESS.md). CI timeouts are provisional until measured green runs exist. Use focused Conventional Commits; publishing requires owner authorization.
