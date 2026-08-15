# Submission Status

Last updated: 2026-08-11

## Repository state

- primary GitHub repo: `Zcxssxx/Zcxproject11`
- competition mirror: `Zcxxffss/MoonNinja`
- GitHub default branch: `main`
- GitLink default branch: `master`
- MoonBit module name: `Zcxssxx/moon-ninja`
- license: Apache-2.0

## Acceptance readiness

- formatting: checked by `moon fmt --check` and CI
- typecheck: checked by `moon check --target all --deny-warn`
- build: checked by `moon build --target all --deny-warn`
- tests: checked by `moon test --target all --deny-warn`
- native tests: explicit CI step plus a real native worker-pool and committed-fixture integration test
- CI: three OSes, all declared targets, explicit build, test, fmt, and API inspection
- CI trigger: explicitly bound to GitHub `main`; MoonBit 0.10.3 is asserted in the workflow
- branch hygiene: GitHub `main` and GitLink `master` are canonical and are synchronized before release
- examples: ready via `examples/sample.build.ninja` and the measured `examples/benchmarks/medium.build.ninja`
- source explanation: ready via `source-attribution.md`, including Ninja/n2 references and license boundaries
- source scale: over 2,500 tracked MoonBit/C lines, measured by the acceptance script
- boundary coverage: parser, validation, graph-cycle, fingerprint, benchmark, diagnostics, and native execution tests
- usable tooling APIs: variables, depfiles, response files, materialized plans, state sidecars, path safety, and command diagnostics
- effective MoonBit source: above 4,000 tracked implementation/test/interface lines; no generated filler was added

## Release state

- synchronized final state is on GitHub `main` and GitLink `master`
- Mooncakes `0.2.0` published and independently resolved with `moon add`

## Mooncakes note

- previous published version: `Zcxssxx/moon-ninja@0.1.2`
- published version: `Zcxssxx/moon-ninja@0.2.0`; next release: `0.3.0`
- package upload and independent `moon add` resolution verified
