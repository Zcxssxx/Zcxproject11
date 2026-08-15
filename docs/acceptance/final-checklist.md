# Final Acceptance Checklist

This checklist maps the committee rejection feedback to evidence that is
committed in the repository and rerunnable with MoonBit 0.10.3.

| Review concern | Evidence |
| --- | --- |
| SCC and cycles | `src/graph.mbt`, `src/graph_boundary_test.mbt`, Tarjan tests |
| Real MTime plus content hash | `src/fingerprint.mbt`, `src/native/file_snapshot.mbt`, `src/native/file_snapshot_test.mbt` |
| Parallel scheduling | `src/graph.mbt`, `src/wave_executor.mbt`, `src/native/parallel_wave.mbt`, `src/native/native_stub.c` |
| Real native execution | `src/ffi_native.mbt`, `src/native_stub.c`, `src/native/parallel_wave_test.mbt` |
| Real workload inputs | `examples/benchmarks/medium.build.ninja`, `examples/fixtures/*.c`, native fixture integration test |
| Parser and graph boundaries | `src/validation_test.mbt`, `src/graph_boundary_test.mbt`, parser tests |
| Explicit build and all target CI | `.github/workflows/test.yml` |
| README commands and scope | `README.md`, `examples/benchmarks/README.md` |
| License and references | `LICENSE`, `source-attribution.md`, README reference section |
| Public development history | GitHub `main` and GitLink `master` commit logs, `CHANGELOG.md` |
| Package metadata | `moon.mod`, `moon publish --dry-run`, independent `moon add` resolution |
| Command/tooling usability | `src/variable_expansion.mbt`, `src/depfile.mbt`, `src/response_file.mbt`, `src/command_line.mbt` |
| Deterministic incremental artifacts | `src/build_plan.mbt`, `src/build_state.mbt`, `src/target_inspection.mbt` |

## Reproducible commands

```bash
moon fmt --check
moon check --target all --deny-warn
moon build --target all --deny-warn
moon test --target all --deny-warn
```

On a native host with GCC/Clang, the final command also runs the real worker
pool and committed-fixture checks. `scripts/verify_acceptance.ps1` additionally
checks the default branch, documentation, license metadata, commit history,
fixture presence, CI branch/toolchain configuration, and the honest
4,000-line tracked source threshold.
