///|
test "plan analysis identifies leaves and critical path" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [
      { rule: "cc", inputs: ["a.c"], outputs: ["a.o"] },
      { rule: "cc", inputs: ["b.c"], outputs: ["b.o"] },
      { rule: "cc", inputs: ["a.o", "b.o"], outputs: ["app"] },
    ],
  }
  match manifest.analyze("app") {
    Ok(analysis) => {
      assert_eq(analysis.edge_count, 3)
      assert_eq(analysis.wave_count, 2)
      assert_eq(analysis.critical_path, 2)
      assert_eq(analysis.max_parallelism, 2)
      assert_eq(analysis.leaf_input_count, 2)
      assert_eq(analysis.produced_output_count, 3)
      assert_true(analysis.leaf_inputs.contains("a.c"))
      assert_true(analysis.leaf_inputs.contains("b.c"))
    }
    Err(error) => abort("analysis failed: " + error)
  }
}

///|
test "plan analysis preserves a useful text summary" {
  match synthetic_fixture(layer_count=6, fanout=2).analyze("artifact") {
    Ok(analysis) => {
      let text = analysis.to_text()
      assert_true(text.contains("critical_path=7"))
      assert_true(text.contains("max_parallelism=2"))
      assert_true(text.contains("target=artifact"))
    }
    Err(error) => abort("synthetic analysis failed: " + error)
  }
}

///|
test "plan analysis rejects a cycle before computing waves" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [
      { rule: "cc", inputs: ["b"], outputs: ["a"] },
      { rule: "cc", inputs: ["a"], outputs: ["b"] },
    ],
  }
  match manifest.analyze("a") {
    Ok(_) => abort("cycle should not produce analysis")
    Err(error) => assert_true(error.contains("Circular dependency"))
  }
}
