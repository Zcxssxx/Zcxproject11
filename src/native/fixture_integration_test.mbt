///|
/// These are committed inputs, not generated placeholders. The native
/// adapter must be able to stat and hash every source used by the benchmark
/// manifest before an execution plan is accepted.
test "native benchmark fixtures are readable" {
  let paths = [
    "examples/fixtures/hello.c", "examples/fixtures/math.c", "examples/fixtures/math.h",
    "examples/fixtures/strings.c", "examples/benchmarks/medium.build.ninja",
  ]
  for path in paths {
    let fingerprint = snapshot_file(path)
    assert_true(fingerprint.size > 0)
    assert_true(fingerprint.content_hash != "0")
  }
}
