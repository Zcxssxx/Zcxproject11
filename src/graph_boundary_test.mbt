///|
test "graph ignores an unreachable cycle when planning a safe target" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [
      { rule: "cc", inputs: ["safe.c"], outputs: ["safe.o"] },
      { rule: "cc", inputs: ["cycle-b"], outputs: ["cycle-a"] },
      { rule: "cc", inputs: ["cycle-a"], outputs: ["cycle-b"] },
    ],
  }
  let graph = DepGraph::build(manifest)
  match graph.traverse("safe.o") {
    Ok(edges) => assert_eq(edges.length(), 1)
    Err(error) => abort("unreachable cycle should not block target: " + error)
  }
}

///|
test "graph reports a self cycle with an SCC diagnostic" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [{ rule: "cc", inputs: ["loop"], outputs: ["loop"] }],
  }
  let graph = DepGraph::build(manifest)
  match graph.parallel_waves("loop") {
    Ok(_) => abort("self cycle should fail")
    Err(error) => assert_true(error.contains("SCC"))
  }
}

///|
test "graph keeps wave order stable across repeated planning" {
  let manifest = synthetic_fixture(layer_count=4, fanout=4)
  let graph = DepGraph::build(manifest)
  let first = graph.parallel_waves("artifact")
  let second = graph.parallel_waves("artifact")
  match (first, second) {
    (Ok(first_waves), Ok(second_waves)) => {
      assert_eq(first_waves.length(), second_waves.length())
      for i, first_wave in first_waves {
        assert_eq(first_wave.length(), second_waves[i].length())
        for j, first_edge in first_wave {
          assert_eq(first_edge.key(), second_waves[i][j].key())
        }
      }
    }
    _ => abort("repeated planning should produce two successful results")
  }
}
