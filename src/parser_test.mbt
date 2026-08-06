///|
test "parser basics" {
  let ninja_input =
    #|rule cc
    #|  command = gcc -c $in -o $out
    #|build main.o: cc main.c
    #|
  let p = Parser::new(ninja_input)
  try {
    let manifest = p.parse()
    let graph = DepGraph::build(manifest)
    match graph.traverse("main.o") {
      Ok(edges) => {
        assert_eq(edges.length(), 1)
        assert_eq(edges[0].rule, "cc")
        assert_eq(edges[0].inputs[0], "main.c")
        assert_eq(edges[0].outputs[0], "main.o")
      }
      Err(e) => abort("Traverse failed: " + e)
    }
  } catch {
    _ => abort("Parse failed")
  }
}

///|
test "parser handles comments multiple outputs and order-only deps" {
  let ninja_input =
    #|# comment
    #|rule cc
    #|  command = gcc -c $in -o $out
    #|build main.o util.o: cc main.c util.c | generated.h || stamp
    #|
  let parser = Parser::new(ninja_input)
  try {
    let manifest = parser.parse()
    assert_eq(manifest.rules.length(), 1)
    assert_eq(manifest.builds.length(), 1)
    let edge = manifest.builds[0]
    assert_eq(edge.outputs.length(), 2)
    assert_eq(edge.inputs.length(), 4)
    assert_eq(edge.inputs[2], "generated.h")
    assert_eq(edge.inputs[3], "stamp")
  } catch {
    _ => abort("Parse failed")
  }
}

///|
test "graph detects cycles" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [
      { rule: "cc", inputs: ["b"], outputs: ["a"] },
      { rule: "cc", inputs: ["a"], outputs: ["b"] },
    ],
  }
  let graph = DepGraph::build(manifest)
  let components = graph.strongly_connected_components()
  assert_eq(components.length(), 1)
  assert_eq(components[0].length(), 2)
  match graph.traverse("a") {
    Ok(_) => abort("Expected cycle detection failure")
    Err(message) =>
      assert_true(message.contains("Circular dependency detected"))
  }
}

///|
test "parallel waves keep independent edges together" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [
      { rule: "cc", inputs: ["one.c"], outputs: ["one.o"] },
      { rule: "cc", inputs: ["two.c"], outputs: ["two.o"] },
      { rule: "cc", inputs: ["one.o", "two.o"], outputs: ["app"] },
    ],
  }
  let graph = DepGraph::build(manifest)
  match graph.parallel_waves("app") {
    Ok(waves) => {
      assert_eq(waves.length(), 2)
      assert_eq(waves[0].length(), 2)
      assert_eq(waves[1].length(), 1)
    }
    Err(error) => abort("Wave planning failed: " + error)
  }
}

///|
test "lock-free wave runner returns deterministic commands" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [
      { rule: "cc", inputs: ["one.c"], outputs: ["one.o"] },
      { rule: "cc", inputs: ["two.c"], outputs: ["two.o"] },
      { rule: "cc", inputs: ["one.o", "two.o"], outputs: ["app"] },
    ],
  }
  let graph = DepGraph::build(manifest)
  let scheduler : Scheduler[DryRunWaveExecutor] = {
    graph,
    executor: DryRunWaveExecutor::{  },
  }
  match scheduler.run_parallel_waves("app") {
    Ok(commands) => {
      assert_eq(commands.length(), 3)
      assert_eq(commands[2], "echo one.o two.o -> app")
    }
    Err(error) => abort("Parallel wave run failed: " + error)
  }
}

///|
test "fingerprint changes trigger a rebuild even with equal mtime" {
  let old_input = FileFingerprint::from_bytes(
    b"old",
    mtime_seconds=100,
    mtime_nanos=1,
  )
  let new_input = FileFingerprint::from_bytes(
    b"new",
    mtime_seconds=100,
    mtime_nanos=1,
  )
  let output = FileFingerprint::from_bytes(
    b"output",
    mtime_seconds=101,
    mtime_nanos=1,
  )
  let edge : BuildEdge = {
    rule: "cc",
    inputs: ["source.c"],
    outputs: ["source.o"],
  }
  let previous = { "source.c": old_input, "source.o": output }
  let current = { "source.c": new_input, "source.o": output }
  match edge.evaluate_fingerprints(current, previous) {
    NeedsBuild(reason) => assert_true(reason.contains("changed"))
    UpToDate => abort("Expected changed input to require a rebuild")
  }
}

///|
test "incremental planning only executes stale edges" {
  let manifest : Manifest = {
    rules: {
      "cc": { name: "cc", command: "gcc -c $in -o $out" },
      "link": { name: "link", command: "gcc $in -o $out" },
    },
    builds: [
      { rule: "cc", inputs: ["main.c"], outputs: ["main.o"] },
      { rule: "cc", inputs: ["util.c"], outputs: ["util.o"] },
      { rule: "link", inputs: ["main.o", "util.o"], outputs: ["app"] },
    ],
  }
  let graph = DepGraph::build(manifest)
  let snapshot : Map[String, Int] = {
    "main.c": 10,
    "util.c": 4,
    "main.o": 8,
    "util.o": 9,
    "app": 7,
  }
  let executor = DryRunExecutor::{  }
  let scheduler = Scheduler::{ graph, executor }
  match scheduler.run_incremental("app", snapshot) {
    Ok(commands) => {
      assert_eq(commands.length(), 2)
      assert_eq(commands[0], "gcc -c main.c -o main.o")
      assert_eq(commands[1], "gcc main.o util.o -o app")
    }
    Err(e) => abort("Incremental run failed: " + e)
  }
}

///|
test "render command fails when rule is missing" {
  let edge : BuildEdge = {
    rule: "missing",
    inputs: ["main.c"],
    outputs: ["main.o"],
  }
  match edge.render_command(Map([])) {
    Ok(_) => abort("Expected missing rule failure")
    Err(message) => assert_eq(message, "Unknown rule: missing")
  }
}
