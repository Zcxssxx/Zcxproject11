# MoonNinja

[![MoonBit](https://img.shields.io/badge/MoonBit-native-blue)](https://www.moonbitlang.cn/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![CI](https://github.com/Zcxssxx/Zcxproject11/actions/workflows/test.yml/badge.svg)](https://github.com/Zcxssxx/Zcxproject11/actions/workflows/test.yml)

MoonNinja is a MoonBit-native subset Ninja build engine for OSC2026. It focuses on the core path that the acceptance review cares about most:

- real `build.ninja`-style text parsing
- dependency-graph construction with cycle detection
- incremental rebuild decisions from file timestamp snapshots
- schedulable command execution with `$in` and `$out` expansion
- reproducible examples, tests, CI, and self-check scripts

The project is intentionally scoped to a well-documented subset of Ninja so that the implementation remains readable, testable, and publishable as a MoonBit ecosystem package.

## Current Scope

MoonNinja currently supports:

- `rule <name>` blocks with `command = ...`
- `build <outputs>: <rule> <inputs>` declarations
- multiple outputs in one build edge
- implicit and order-only dependencies written with `|` and `||`
- comments beginning with `#`
- topological traversal and cycle detection
- incremental stale-check decisions driven by a file timestamp snapshot
- native command execution and WASM-side mock execution

MoonNinja does not yet aim to be a drop-in replacement for the full Ninja specification. The repository documents this boundary explicitly and tests the supported subset end to end.

## Quick Start

```bash
moon fmt --check
moon check --deny-warn
moon test --deny-warn
moon run src/main
```

Native backend validation:

```bash
moon test --deny-warn --target native
```

Acceptance self-check:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify_acceptance.ps1
```

## Example

Example input file: [examples/sample.build.ninja](examples/sample.build.ninja)

```ninja
rule cc
  command = gcc -c $in -o $out
rule link
  command = gcc $in -o $out

build util.o: cc util.c
build main.o: cc main.c | generated.h
build app: link main.o util.o
```

The demo entry at [src/main/main.mbt](src/main/main.mbt) parses a manifest like the one above, builds a dependency graph, evaluates which targets are stale, and executes only the required commands.

## Repository Layout

```text
MoonNinja/
|- .github/workflows/test.yml   GitHub Actions CI
|- examples/sample.build.ninja  Realistic parser input example
|- scripts/verify_acceptance.ps1
|- moon.mod                     MoonBit module metadata for publication
|- src/
|  |- manifest.mbt              Manifest and command rendering
|  |- lexer.mbt                 Tokenization for the supported Ninja subset
|  |- parser.mbt                Parser for rule/build declarations
|  |- graph.mbt                 Dependency graph and cycle detection
|  |- incremental.mbt           Incremental rebuild decision logic
|  |- scheduler.mbt             Planning and incremental execution
|  |- local_executor.mbt        Native command execution adapter
|  |- parser_test.mbt           Core-path tests
|  `- main/main.mbt             Demo CLI entry
|- official-requirements.md     OSC2026 requirement notes
|- source-attribution.md        Source explanation and implementation boundaries
`- submission-status.md         Local closeout status and reviewer checklist
```

## Mooncakes Metadata

The package metadata needed for Mooncakes publication is declared in [moon.mod](moon.mod):

- module name: `Zcxssxx/moon-ninja`
- license: `Apache-2.0`
- repository: `https://github.com/Zcxssxx/Zcxproject11`
- readme: `README.md`

Before publishing, use:

```bash
moon publish --dry-run
```

## Competition Notes

- GitHub primary repo: [Zcxssxx/Zcxproject11](https://github.com/Zcxssxx/Zcxproject11)
- GitLink mirror: [Zcxxffss/MoonNinja](https://gitlink.org.cn/Zcxxffss/MoonNinja)
- The GitHub repo is used for CI and Mooncakes-facing metadata.
- The GitLink repo is kept as the competition mirror and can remain single-contributor on that platform.

## Verification Checklist

- [x] `moon fmt --check`
- [x] `moon check --deny-warn`
- [x] `moon test --deny-warn`
- [x] `moon test --deny-warn --target native`
- [x] CI workflow for Linux, macOS, and Windows
- [x] License file present
- [x] README explains scope, usage, examples, and package metadata
- [x] Acceptance self-check script included

## License

Apache License 2.0. See [LICENSE](LICENSE).
