# MoonNinja

[![MoonBit](https://img.shields.io/badge/MoonBit-native-blue)](https://www.moonbitlang.cn/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![CI](https://github.com/Zcxssxx/Zcxproject11/actions/workflows/test.yml/badge.svg)](https://github.com/Zcxssxx/Zcxproject11/actions/workflows/test.yml)

MoonNinja is a MoonBit-native subset Ninja build engine for OSC2026. It focuses on the core path that the acceptance review cares about most:

- real `build.ninja`-style text parsing
- dependency-graph construction with Tarjan SCC diagnostics and cycle detection
- incremental rebuild decisions from real native MTime plus content hash snapshots
- deterministic lock-free dependency waves for host-provided parallel runners
- native command execution through a bounded atomic-index worker pool and a real WASM-GC/JS host execution ABI
- schedulable command rendering with `$in` and `$out` expansion
- named variable expansion, Make-style depfile ingestion, and response-file materialization
- deterministic inspectable build plans, persistent state sidecars, path safety, and command validation
- reproducible examples, committed C benchmark inputs, boundary tests, CI, and self-check scripts

The project is intentionally scoped to a well-documented subset of Ninja so that the implementation remains readable, testable, and publishable as a MoonBit ecosystem package.

## Current Scope

MoonNinja currently supports:

- `rule <name>` blocks with `command = ...`
- `build <outputs>: <rule> <inputs>` declarations
- multiple outputs in one build edge
- implicit and order-only dependencies written with `|` and `||`
- comments beginning with `#`
- topological traversal and cycle detection
- strongly connected component reporting for cyclic manifests
- incremental stale-check decisions driven by MTime plus content fingerprints
- native `stat`/streaming-hash snapshots through `src/native/native_stub.c`
- native process execution through `system`
- native parallel-wave execution through `NativeParallelWaveExecutor`, with bounded workers and deterministic failure indices
- WASM-GC host import `moon_ninja.execute_command` and JS host import `MoonNinjaHost.execute_command`
- portable `ExpansionContext`, `Depfile`, `MaterializedPlan`, `BuildState`, and `CommandLine` APIs

MoonNinja does not yet aim to be a drop-in replacement for the full Ninja specification. The repository documents this boundary explicitly and tests the supported subset end to end.

## Quick Start

```bash
moon fmt --check
moon check --deny-warn
moon build --target all
moon test --deny-warn
moon run src/main
```

Native backend validation:

```bash
moon test --deny-warn --target native
```

The default demo is intentionally plan-only, so it is runnable on every
backend. Native command execution is covered by the native-only integration
test and requires a C compiler. WASM-GC command execution is not a fake local
process: the host must provide an import named `moon_ninja.execute_command`
whose argument is a MoonBit `String` and whose return value is an integer exit
code. JavaScript hosts provide the equivalent `MoonNinjaHost.execute_command`.

For the full backend matrix, run:

```bash
moon check --target all --deny-warn
moon build --target all --deny-warn
moon test --target all --deny-warn
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

The demo entry at [src/main/main.mbt](src/main/main.mbt) parses a manifest like the one above, builds a dependency graph, evaluates which targets are stale, and prints the commands that would execute. `LocalExecutor` is available for native hosts; `DryRunExecutor` is used by the portable demo.

## Fixture benchmark and boundary coverage

[examples/benchmarks/medium.build.ninja](examples/benchmarks/medium.build.ninja)
is a committed, reproducible workload. It compiles three real C inputs, tracks
a header dependency, archives two objects, and links a downstream demo. The
inputs live in [examples/fixtures](examples/fixtures), so CI never depends on
files that are created implicitly by a test.

[examples/benchmarks/large.build.ninja](examples/benchmarks/large.build.ninja)
adds ten independent compile edges, two header families, an archive, and a
final link. It is intended for stable wave-width and transitive-input
inspection rather than synthetic line counting.

The public `Manifest::benchmark` and `Manifest::analyze` APIs report edge and
node counts, dependency depth, wave width, fan-in/fan-out, leaf inputs, and
rendered commands. `src/validation_test.mbt`, `src/graph_boundary_test.mbt`,
and the parser tests cover empty outputs, duplicate declarations, unknown
rules/targets, self-cycles, multi-node cycles, disconnected cycles, order-only
inputs, CRLF text, punctuation in paths, and missing/change-sensitive
fingerprints.

The checked-in implementation and tests contain more than 2,500 lines of
effective MoonBit source and more than 4,000 tracked MoonBit/C implementation
and test/interface lines. These are evidence-based counts performed by
`scripts/verify_acceptance.ps1`, not generated filler; the competition guidance
also makes clear that maintainable scope and working evidence matter more than
an arbitrary line count.

For a target-level explanation, call `Manifest::inspect_target`. For a stable
execution artifact, call `Manifest::materialize_plan`, then serialize
`BuildState::to_text` after a successful host run. Compiler-generated depfiles
can be parsed with `parse_depfile` and merged into the producing edge. Commands
that use `@flags.rsp` can be expanded from an in-memory response-file table with
`materialize_response_command`; no host filesystem access is required by these
portable APIs.

## Design notes

`DepGraph::strongly_connected_components` uses Tarjan's algorithm and reports
the complete cyclic component. `DepGraph::parallel_waves` emits independent
ready sets in deterministic order. `Scheduler::run_parallel_waves` never
shares a mutable ready queue between waves; a native thread-pool or WASM host
can implement `WaveExecutor` to run each wave concurrently.

`FileFingerprint` stores seconds, nanoseconds, size, and a portable 64-bit
content hash. The native adapter reads real file metadata and streams the file
through the hash; equal timestamps therefore do not hide content changes.

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
|  |- graph.mbt                 SCC diagnostics and dependency waves
|  |- incremental.mbt           MTime/hash rebuild decision logic
|  |- fingerprint.mbt           Portable file identity model
|  |- scheduler.mbt             Planning and incremental execution
|  |- wave_executor.mbt         Lock-free wave runner interface
|  |- local_executor.mbt        Native command execution adapter
|  |- benchmark.mbt             Measured workload summaries
|  |- plan_analysis.mbt         Critical-path and parallelism analysis
|  |- validation.mbt            Manifest validation diagnostics
|  |- diagnostics.mbt           Actionable parse/graph diagnostics
|  |- variable_expansion.mbt    Named and built-in command variables
|  |- depfile.mbt               Make-style compiler dependency files
|  |- response_file.mbt         Quoted response-file arguments
|  |- build_plan.mbt            Stable materialized target plans
|  |- build_state.mbt           Incremental state sidecar format
|  |- path_utils.mbt            Cross-platform safe build paths
|  |- command_line.mbt          Structured command rendering
|  |- command_validation.mbt    Pre-execution command diagnostics
|  |- target_inspection.mbt     Read-only dependency explanations
|  |- dependency_diff.mbt       Stable depfile change reports
|  |- native/                   Native stat/hash adapter, worker pool, and fixture tests
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

## Reference projects and license boundary

MoonNinja targets a documented subset of the Ninja file model. The
interoperability references are:

- [Ninja](https://github.com/ninja-build/ninja), an Apache-2.0 build system;
  see its [license](https://github.com/ninja-build/ninja/blob/master/COPYING).
- [n2](https://github.com/evmar/n2), a Ninja-compatible Apache-2.0 build
  system; see its [license](https://github.com/evmar/n2/blob/main/LICENSE).

No Ninja or n2 source is copied into this repository. Their syntax and public
documentation are referenced only to define compatibility scope; this project
contains original MoonBit code under its own Apache License 2.0.

## Verification Checklist

- [x] `moon fmt --check` (run locally and in CI)
- [x] CI push trigger is explicitly bound to GitHub `main`
- [x] CI verifies MoonBit 0.10.3
- [x] `moon check --target all --deny-warn`
- [x] `moon build --target all --deny-warn`
- [x] `moon test --target all --deny-warn`
- [x] native integration test with a system C compiler
- [x] CI workflow for Linux, macOS, and Windows
- [x] License file present
- [x] README explains scope, usage, examples, package metadata, and references
- [x] Acceptance self-check script included

## License

Apache License 2.0. See [LICENSE](LICENSE).
