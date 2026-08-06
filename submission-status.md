# Submission Status

Last updated: 2026-08-06

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
- native tests: explicit CI step; local run requires a C compiler
- CI: three OSes, all declared targets, build, test, fmt, and API diff
- examples: ready via `examples/sample.build.ninja`
- source explanation: ready via `source-attribution.md`, including Ninja/n2 references

## Remaining release actions

- keep the synchronized final state on GitHub `main` and GitLink `master`

## Mooncakes note

- previous published version: `Zcxssxx/moon-ninja@0.1.1`
- target release version: `Zcxssxx/moon-ninja@0.1.2`
- publish only after the owner session confirms CI is green
