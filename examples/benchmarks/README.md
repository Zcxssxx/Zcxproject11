# Benchmark workloads

medium.build.ninja is a committed workload used by the benchmark and
acceptance documentation. It has independent compile edges, a header
dependency, an archive edge, and a downstream link edge.

large.build.ninja is a second committed workload with ten independent compile
edges, two header families, an archive edge, and a final link edge. It is used
to inspect stable wave width and transitive input counts without generating
source files during the test.

Run the portable parser/graph benchmark with:

    moon run src/main

The benchmark API also accepts the file contents directly, which keeps tests
hermetic and makes the measured edge/wave counts reproducible in CI.

The new portable tooling APIs are intentionally tested with in-memory inputs:
depfiles can be parsed and merged, response files can be materialized from a
map, and a `MaterializedPlan` can be serialized into a `BuildState` sidecar.
