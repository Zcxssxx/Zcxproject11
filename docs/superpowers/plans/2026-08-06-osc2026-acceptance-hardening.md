# OSC2026 Acceptance Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make MoonNinja reproducibly verifiable against the OSC2026 acceptance feedback on current MoonBit tooling, then synchronize the validated result to GitHub and GitLink.

**Architecture:** Keep the parser and public graph API target-neutral. Add Tarjan SCC diagnostics and deterministic dependency waves to the graph, add a portable content fingerprint model plus a self-contained native filesystem stub for real mtime/hash reads, and expose a no-shared-queue wave-runner interface for native or host thread pools. Replace the WASM mock with an explicit host-import ABI and make the default demo plan-only so `moon run` remains deterministic without a host.

**Tech Stack:** MoonBit, `moonbitlang/x` crypto/fs, `moonbitlang/async` native task groups, GitHub Actions on Ubuntu/macOS/Windows, PowerShell acceptance checks.

---

### Task 1: Reproduce current failures and add regression tests

**Files:**
- Modify: `src/parser_test.mbt`
- Create: `src/native_executor_test.mbt`

- [ ] Add a test using a recording executor instead of executing `gcc` against nonexistent fixture files; assert the two stale commands and their order.
- [ ] Add a native-only test that invokes `LocalExecutor` with `echo MoonNinja native executor`, proving the real native FFI path without external source files.
- [ ] Run `moon fmt --check`, `moon check --deny-warn`, and `moon test --deny-warn` to capture the expected current failures before implementation.

### Task 2: Harden current-toolchain syntax and target configuration

**Files:**
- Modify: `src/graph.mbt`, `src/parser.mbt`, `src/parser_test.mbt`, `src/main/main.mbt`
- Modify: `src/main/moon.pkg`, `src/moon.pkg`

- [ ] Replace ambiguous typed `{}` map literals with `Map([])`.
- [ ] Replace deprecated executable metadata with `pkgtype(kind: "executable")`.
- [ ] Add explicit target selection for native-only tests and backend-specific FFI files.
- [ ] Run `moon fmt` and inspect the diff before continuing.

### Task 3: Add SCC diagnostics and deterministic parallel waves

**Files:**
- Modify: `src/graph.mbt`
- Modify: `src/parser_test.mbt`

- [ ] Implement `DepGraph::strongly_connected_components` with Tarjan indices, low-link values, and an explicit stack.
- [ ] Make traversal report the complete cyclic SCC, including self-loops, before doing the normal topological traversal.
- [ ] Implement `DepGraph::parallel_waves` as deterministic antichains of independent build edges.
- [ ] Add tests for a two-node SCC, a self-loop, and two independent edges sharing a wave.

### Task 4: Add real MTime + SHA-256 incremental state

**Files:**
- Modify: `moon.mod`, `src/moon.pkg`, `src/incremental.mbt`, `src/parser_test.mbt`
- Create: `src/fingerprint.mbt`
- Create: `src/native/moon.pkg`
- Create: `src/native/file_snapshot.mbt`
- Create: `src/native/file_snapshot_test.mbt`

- [ ] Add `moonbitlang/x@0.4.48` with `moon add`.
- [ ] Define public `FileFingerprint` containing seconds, nanoseconds, size, and SHA-256, with equality and ordering helpers.
- [ ] Add `BuildEdge::evaluate_fingerprints(current, previous)` so same-mtime content changes still trigger rebuilds.
- [ ] Use a self-contained C native stub for `stat`, file size, and streaming content hashing; keep the fingerprint model target-neutral.
- [ ] Add tests for unchanged fingerprints, changed hash at equal mtime, missing outputs, and a real repository file read on native.

### Task 5: Add lock-free native parallel execution and a real WASM host ABI

**Files:**
- Modify: `src/scheduler.mbt`, `src/ffi_wasm.mbt`, `src/ffi_native.mbt`
- Create: `src/wave_executor.mbt`
- Create: `src/ffi_js.mbt`
- Modify: `src/moon.pkg`
- Modify: `src/main/main.mbt`

- [ ] Add a target-neutral scheduler that hands each independent dependency wave to a `WaveExecutor`; the core never shares a mutable ready queue or mutex, so native/host runners can use their own thread pools.
- [ ] Replace the WASM print-and-return mock with an imported host function `moon_ninja.execute_command`; provide the equivalent JS host import.
- [ ] Keep the default CLI demo plan-only and expose rendered commands so it runs without pretending that a WASM process host exists.
- [ ] Add a native parallel test with independent `echo` commands and assert all results complete.

### Task 6: Make CI and acceptance documentation reproducible

**Files:**
- Modify: `.github/workflows/test.yml`, `scripts/verify_acceptance.ps1`, `README.md`, `official-requirements.md`, `source-attribution.md`, `submission-status.md`

- [ ] Align CI with the MoonBit community template: install on all three OSes, run `moon version --all`, `moon update`, `moon check --target all`, `moon build --target all`, `moon test --target all`, `moon fmt`, and `moon info` with clean diffs.
- [ ] Run native integration tests only on native and keep WASM builds explicit; do not claim an unhosted WASM process execution.
- [ ] Make the acceptance script check CI, target coverage, source scale, default branch visibility, real SCC/fingerprint/parallel/WASM-host documentation, and both default-branch names.
- [ ] Add Ninja and n2 reference links, their Apache-2.0 notices, the subset boundary, and the exact host ABI/commands to the README and attribution notes.

### Task 7: Validate and synchronize repositories

**Files:**
- GitHub default branch: `main`
- GitLink default branch: `master`

- [ ] Run the complete local check matrix and the acceptance script with remote and Mooncakes checks enabled where authorized.
- [ ] Run `moon info`, inspect `git diff`, and verify tracked MoonBit line counts and commit authors.
- [ ] Commit with the existing creator identity `Zcxssxx <1986519765@qq.com>`.
- [ ] Apply the same tree to GitLink without adding a second author, verify `origin/HEAD`, and push only after both worktrees are clean and validated.
