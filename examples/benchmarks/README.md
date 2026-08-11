# Benchmark workloads

medium.build.ninja is a committed workload used by the benchmark and
acceptance documentation. It has independent compile edges, a header
dependency, an archive edge, and a downstream link edge.

Run the portable parser/graph benchmark with:

    moon run src/main

The benchmark API also accepts the file contents directly, which keeps tests
hermetic and makes the measured edge/wave counts reproducible in CI.
