///|
test "benchmark summary measures a committed style workload" {
  let input =
    #|rule cc
    #|  command = gcc -c $in -o $out
    #|rule link
    #|  command = gcc $in -o $out
    #|build math.o: cc examples/fixtures/math.c | examples/fixtures/math.h
    #|build strings.o: cc examples/fixtures/strings.c | examples/fixtures/math.h
    #|build app: link math.o strings.o
    #|
  match benchmark_from_ninja(input, "app") {
    Ok(report) => {
      assert_eq(report.summary.rule_count, 2)
      assert_eq(report.summary.edge_count, 3)
      assert_true(report.summary.node_count >= 6)
      assert_eq(report.summary.wave_count, 2)
      assert_eq(report.summary.max_wave_width, 2)
      assert_true(report.summary.command_count == 3)
      assert_true(report.rendered_commands.length() == 3)
    }
    Err(error) => abort("benchmark parse failed: " + error)
  }
}

///|
test "deterministic fixture exposes depth and fanout" {
  let manifest = synthetic_fixture(layer_count=5, fanout=3)
  match manifest.benchmark("artifact") {
    Ok(report) => {
      let summary = report.summary
      assert_eq(summary.rule_count, 1)
      assert_true(summary.edge_count >= 15)
      assert_true(summary.dependency_depth >= 4)
      assert_true(summary.max_wave_width >= 3)
      assert_true(summary.fanout >= 3)
    }
    Err(error) => abort("synthetic benchmark failed: " + error)
  }
}

///|
test "benchmark report rejects an unknown target" {
  let manifest = synthetic_fixture(layer_count=2, fanout=2)
  match manifest.benchmark("does-not-exist") {
    Ok(_) => abort("unknown target should fail")
    Err(error) => assert_true(error.contains("target"))
  }
}

///|
test "benchmark report text is stable and actionable" {
  let manifest = synthetic_fixture(layer_count=3, fanout=2)
  match manifest.benchmark("artifact").map(report => report.summary.to_text()) {
    Ok(text) => {
      assert_true(text.contains("edges="))
      assert_true(text.contains("waves="))
      assert_true(text.contains("max_wave_width="))
    }
    Err(error) => abort("report text failed: " + error)
  }
}
