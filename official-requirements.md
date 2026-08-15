# OSC2026 Acceptance Notes

This repository is maintained against the current public OSC2026 guidance and the pre-acceptance feedback returned by the committee.

## Official requirements rechecked on 2026-08-15

- proposal window: 2026-04-29 to 2026-07-10
- acceptance window: 2026-07-11 to 2026-07-17
- proposal materials include participant information, a public repository link, and a one-page PDF proposal

## What this repo now demonstrates

- public source repository
- Apache 2.0 license
- README with runnable instructions and implementation boundaries
- MoonBit CI
- MoonBit package metadata for Mooncakes publication
- real parser, dependency graph, incremental decision logic, execution path, and tests
- committed C inputs with measured benchmark reports and native fixture hashing
- native atomic-index worker-pool execution for an independent dependency wave
- actionable validation/diagnostic APIs and boundary regression tests
- practical build-tool APIs for variables, depfiles, response files, plan
  inspection, state persistence, path safety, and command validation

## Review focus derived from the committee feedback

1. `moon fmt --check` must pass on the latest toolchain.
2. CI should cover all three hosted operating systems and all declared MoonBit targets.
3. `moon build` must be explicit in CI; tests must not invoke commands with missing fixture inputs.
4. The implementation must expose real SCC, MTime+hash, lock-free wave planning, and native/WASM host execution paths.
5. Mooncakes metadata should be recognizable and publishable.
6. Tests and examples should cover the main execution path, real inputs, and failure boundaries.
7. The source count is reported from tracked MoonBit/C files; pure `.mbt`
   source is above 4,000 without generated filler.
8. GitHub CI must trigger on the canonical `main` branch and verify MoonBit
   0.10.3, while GitLink keeps `master` as its canonical mirror branch.

The official site describes 4-10k effective MoonBit LOC as a reference range,
while emphasizing usable scope, complete documentation, runnable tests, and
maintainability. This repository reports its tracked source scale honestly in
the acceptance script rather than padding generated files.
