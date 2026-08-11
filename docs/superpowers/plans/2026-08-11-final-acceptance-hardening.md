# OSC2026 Final Acceptance Hardening Implementation Plan

> **For agentic workers:** Execute this plan inline with verification checkpoints. Keep the GitHub and GitLink trees synchronized, and publish only after the final package checks pass.

**Goal:** Close every committee rejection item, expand the project with real build fixtures and boundary coverage, honestly exceed 2500 tracked MoonBit/C lines, and publish the verified release to Mooncakes.

**Architecture:** Keep the parser/graph/incremental core package portable. Add a fixture-driven benchmark/report layer for measurable real workloads, and add a native worker-pool adapter that executes one dependency wave in parallel without a shared MoonBit ready queue. Document the exact supported Ninja subset and unsupported syntax.

**Tech Stack:** MoonBit 0.10.x, native C FFI, WASM-GC/JS host ABI, GitHub Actions, PowerShell acceptance audit.

---

### Task 1: Establish the rejection-to-evidence checklist

**Files:**
- Modify: `official-requirements.md`
- Modify: `submission-status.md`
- Modify: `scripts/verify_acceptance.ps1`
- Modify: `README.md`

- [x] Record each committee rejection item with an observable file, command, or test.
- [x] Make the self-check fail if the README contains stale commands, unchecked completion claims, missing fixture paths, or source scale below 2500 tracked implementation/test lines.
- [x] Add separate checks for real benchmark fixtures, parser boundary tests, native worker execution, and explicit license/reference links.

### Task 2: Add real benchmark fixtures and measured workload APIs

**Files:**
- Create: `examples/fixtures/hello.c`
- Create: `examples/fixtures/math.c`
- Create: `examples/fixtures/math.h`
- Create: `examples/fixtures/strings.c`
- Create: `examples/fixtures/README.md`
- Create: `examples/benchmarks/medium.build.ninja`
- Create: `src/benchmark.mbt`
- Create: `src/benchmark_test.mbt`

- [x] Define fixture manifests that refer only to committed input files and exercise compile, header, order-only, and link edges.
- [x] Add public benchmark summaries for edge count, node count, dependency depth, wave count, fan-in, fan-out, and command count.
- [x] Test the measured summaries against the committed medium fixture and a generated larger deterministic fixture.

### Task 3: Strengthen parser, graph, and incremental boundary behavior

**Files:**
- Create: `src/validation.mbt`
- Create: `src/validation_test.mbt`
- Modify: `src/parser.mbt`
- Modify: `src/parser_test.mbt`
- Modify: `src/graph.mbt`
- Modify: `src/incremental.mbt`

- [x] Validate empty outputs, missing rules, duplicate producers, malformed separators, CRLF input, comments, paths with punctuation, self-cycles, multi-node cycles, disconnected cycles, missing snapshots, same-mtime content changes, changed outputs, and order-only dependencies.
- [x] Return actionable diagnostics with line/column or edge/key context.
- [x] Keep all boundary cases deterministic and add regression tests before implementation changes.

### Task 4: Provide real native parallel-wave execution

**Files:**
- Create: `src/native/parallel_wave.mbt`
- Create: `src/native/parallel_wave_test.mbt`
- Modify: `src/native/native_stub.c`
- Modify: `src/wave_executor.mbt`
- Modify: `src/scheduler.mbt`

- [x] Use the existing deterministic wave planner to submit independent commands to a native worker pool.
- [x] Keep result collection indexed and deterministic; do not expose a shared mutable ready queue to MoonBit code.
- [x] Return non-zero exit statuses and command indices as structured errors.
- [x] Add a native integration test using committed fixtures and explicit output checks.

### Task 5: Add operational documentation and release evidence

**Files:**
- Modify: `README.md`
- Modify: `source-attribution.md`
- Modify: `submission-status.md`
- Create: `CHANGELOG.md`
- Create: `docs/acceptance/final-checklist.md`

- [x] Document install, package import, CLI/demo, fixture benchmark, native execution, WASM-GC/JS host ABI, supported/unsupported syntax, and reproducible commands.
- [x] Add a changelog and an evidence table that points to source files, tests, CI jobs, and remote branch state.
- [x] State the Apache-2.0 boundary and the Ninja/n2 reference relationship without implying copied source.

### Task 6: Verify, synchronize, publish, and verify again

**Files:**
- Modify: `.github/workflows/test.yml` only if required by the new native test.
- Modify: `moon.mod` for the next monotonically increasing version.

- [x] Run `moon fmt --check`, `moon info`, `moon check --target all --deny-warn`, `moon build --target all --deny-warn`, and `moon test --target all --deny-warn`.
- [x] Run the acceptance script and inspect tracked source scale, default branches, README/license/docs, fixture completeness, and commit history.
- [x] Commit and push GitHub `main`, mirror GitLink `master`, run `moon publish --frozen`, then independently resolve the published version with `moon add`.

---

**Self-review:** The plan covers the rejection list, real inputs, boundary behavior, native execution, documentation, source-scale evidence, CI, repository synchronization, and Mooncakes release verification. It does not add external dependencies or claim linear-WASM process execution where the host ABI cannot provide it.
