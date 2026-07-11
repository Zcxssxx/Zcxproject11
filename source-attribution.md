# Source Attribution

MoonNinja is a self-contained MoonBit implementation written for the OSC2026 competition track around engineering infrastructure and build tooling.

## Original implementation in this repository

- lexer for the supported Ninja subset
- parser for `rule` and `build` declarations
- dependency graph traversal and cycle detection
- incremental rebuild decision logic based on timestamp snapshots
- command rendering for `$in` and `$out`
- native and WASM execution adapters
- acceptance verification script and CI wiring

## Deliberate scope boundary

This project implements a documented subset of Ninja rather than the full language. That boundary is intentional:

- it keeps the codebase understandable during acceptance review
- it allows end-to-end tests over every supported feature
- it avoids presenting unsupported behavior as complete

## External references used only as standards or interoperability targets

- Ninja file syntax as the conceptual compatibility target
- MoonBit toolchain and Mooncakes publication rules
- OSC2026 official public requirement pages

No third-party source tree is vendored into this repository.
