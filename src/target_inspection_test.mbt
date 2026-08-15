///|
test "target inspection explains direct and transitive dependencies" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "cc $in -o $out" } },
    builds: [
      { rule: "cc", inputs: ["main.c"], outputs: ["main.o"] },
      { rule: "cc", inputs: ["main.o", "config.h"], outputs: ["app"] },
    ],
  }
  match manifest.inspect_target("app") {
    Err(error) => abort(error)
    Ok(info) => {
      assert_true(info.direct_inputs == ["main.o", "config.h"])
      assert_true(info.transitive_inputs.contains("main.c"))
      assert_true(info.leaf_inputs.contains("main.c"))
      assert_true(info.leaf_inputs.contains("config.h"))
      assert_eq(info.edge_count, 2)
      assert_true(info.to_text().contains("depth=2"))
    }
  }
}

///|
test "target inspection distinguishes source and missing targets" {
  let manifest : Manifest = { rules: {}, builds: [] }
  match manifest.inspect_target("main.c") {
    Ok(_) => abort("unknown source should not be treated as a target")
    Err(error) => assert_true(error.contains("not produced"))
  }
  match manifest.inspect_target("missing") {
    Ok(_) => abort("missing target should fail")
    Err(error) => assert_true(error.contains("not produced"))
  }
}
