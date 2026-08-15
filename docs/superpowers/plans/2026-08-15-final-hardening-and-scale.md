# Final Acceptance Hardening and Scale Implementation Plan

> **For agentic workers:** Execute this plan task-by-task with test-first checkpoints. Keep GitHub `main` and GitLink `master` synchronized after verification.

**Goal:** Close the CI/default-branch audit findings and expand MoonNinja with real build-tool features so effective MoonBit source exceeds 4,000 lines without filler.

**Architecture:** Preserve the existing parser, graph, incremental, and host-execution core. Add focused portable modules for variable expansion, depfile ingestion, response-file parsing, and deterministic execution-plan materialization. Keep native-only filesystem/process behavior behind the existing native package and make all new public behavior reproducible through tests and committed examples.

**Tech Stack:** MoonBit 0.10.3, native C FFI already present, GitHub Actions, PowerShell acceptance audit, Apache-2.0.

---

### Task 1: Fix CI and branch hygiene

**Files:**
- Modify: `.github/workflows/test.yml`
- Modify: `scripts/verify_acceptance.ps1`
- Modify: `README.md`

- [x] Replace the non-interpolating `$default-branch` trigger with an explicit `main` push trigger.
- [x] Add a toolchain assertion so CI fails unless `moonc` reports 0.10.3, matching the committee environment.
- [x] Add acceptance checks for the workflow trigger, toolchain assertion, and no stale default-branch marker.
- [x] Document that GitHub `main` and GitLink `master` are the canonical branches.

### Task 2: Add variable and command expansion

**Files:**
- Create: `src/variable_expansion.mbt`
- Create: `src/variable_expansion_test.mbt`
- Modify: `src/manifest.mbt`

- [x] Test `$in`, `$out`, `$in_newline`, named variables, escaped dollars, and missing variables.
- [x] Implement deterministic expansion with an explicit `ExpansionContext` and bounded recursive variable resolution.
- [x] Route `BuildEdge::render_command` through the expansion context while preserving the existing API.

### Task 3: Add depfile ingestion

**Files:**
- Create: `src/depfile.mbt`
- Create: `src/depfile_test.mbt`
- Modify: `src/manifest.mbt`

- [x] Test escaped spaces, escaped colons, line continuations, duplicate dependencies, and malformed depfiles.
- [x] Implement a portable Make-style depfile parser and deterministic dependency merge.
- [x] Expose a method that applies depfile dependencies to a selected output without mutating unrelated edges.

### Task 4: Add response-file support

**Files:**
- Create: `src/response_file.mbt`
- Create: `src/response_file_test.mbt`
- Modify: `src/manifest.mbt`

- [x] Test quoted arguments, escaped quotes, comments, whitespace, and empty response files.
- [x] Implement a small platform-neutral response-file lexer and command materializer.
- [x] Document the supported response-file subset and explicit non-goals.

### Task 5: Add deterministic materialized build plans

**Files:**
- Create: `src/build_plan.mbt`
- Create: `src/build_plan_test.mbt`
- Modify: `src/benchmark.mbt`

- [x] Test plan ordering, grouped waves, dependency closure, duplicate output rejection, and actionable missing-target errors.
- [x] Implement `MaterializedPlan` with stable edge order, wave metadata, rendered commands, and input/output summaries.
- [x] Include plan metrics in benchmark reports without changing existing output semantics.

### Task 6: Expand real fixtures and documentation

**Files:**
- Create: `examples/benchmarks/large.build.ninja`
- Create: `examples/fixtures/config.h`
- Create: `examples/fixtures/parser.c`
- Create: `examples/fixtures/codec.c`
- Modify: `examples/benchmarks/README.md`
- Modify: `README.md`
- Modify: `docs/acceptance/final-checklist.md`
- Modify: `submission-status.md`

- [x] Add a larger committed workload using independent waves and real fixture inputs.
- [x] Document reproducible benchmark and plan-inspection commands.
- [x] Report both pure `.mbt` and total tracked implementation/test source counts honestly.

### Task 7: Verify, synchronize, publish, and audit

- [x] Run targeted red-green tests, format, check, build, and test on WASM-GC/JS.
- [x] Run native check/build/test from an ASCII path with GCC.
- [x] Run the acceptance script and verify remote GitHub/GitLink heads and tree equality.
- [x] Push GitHub `main`, fast-forward GitHub `master`, push GitLink `master`, and fast-forward GitLink `main`.
- [x] Publish the monotonic Mooncakes version and independently resolve it.
