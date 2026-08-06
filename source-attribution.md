# Source Attribution

MoonNinja is a self-contained MoonBit implementation written for the OSC2026 competition track around engineering infrastructure and build tooling.

## Original implementation in this repository

- lexer for the supported Ninja subset
- parser for `rule` and `build` declarations
- dependency graph traversal and cycle detection
- Tarjan strongly connected component diagnostics and deterministic dependency waves
- incremental rebuild decision logic based on native MTime and content fingerprints
- command rendering for `$in` and `$out`
- native `stat`/streaming-hash and `system` adapters
- WASM-GC and JavaScript host execution adapters
- acceptance verification script and CI wiring

## Deliberate scope boundary

This project implements a documented subset of Ninja rather than the full language. That boundary is intentional:

- it keeps the codebase understandable during acceptance review
- it allows end-to-end tests over every supported feature
- it avoids presenting unsupported behavior as complete

## External references used only as standards or interoperability targets

- [Ninja](https://github.com/ninja-build/ninja) file syntax and build semantics
- [n2](https://github.com/evmar/n2) as a second Ninja-compatible implementation
- MoonBit toolchain and Mooncakes publication rules
- OSC2026 official public requirement pages

Ninja and n2 are Apache-2.0 projects. Their licenses are linked above for
reference; no third-party source tree is vendored into this repository.
