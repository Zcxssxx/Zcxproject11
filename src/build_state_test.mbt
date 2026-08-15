///|
test "build state round trips a materialized plan" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "cc $in -o $out" } },
    builds: [{ rule: "cc", inputs: ["main.c"], outputs: ["main.o"] }],
  }
  match manifest.materialize_plan("main.o", Map([])) {
    Err(error) => abort(error)
    Ok(plan) => {
      let state = BuildState::from_plan(plan)
      match parse_build_state(state.to_text()) {
        Err(error) => abort(error)
        Ok(restored) => {
          assert_true(restored == state)
          assert_true(
            !restored.needs_rebuild("cc::main.o", "cc main.c -o main.o"),
          )
          assert_true(
            restored.needs_rebuild("cc::main.o", "cc main.c -o other.o"),
          )
        }
      }
    }
  }
}

///|
test "build state preserves escaped paths and output lookup" {
  let state : BuildState = {
    entries: [
      {
        edge_key: "cc::build/app",
        command_hash: "123",
        outputs: ["build/app", "build/space file.o"],
      },
    ],
  }
  match parse_build_state(state.to_text()) {
    Err(error) => abort(error)
    Ok(restored) =>
      match restored.find("cc::build/app") {
        None => abort("state entry was lost")
        Some(entry) => assert_true(entry.outputs.contains("build/space file.o"))
      }
  }
}

///|
test "build state rejects corrupt records" {
  match parse_build_state("# MoonNinja build state v1\nmissing-fields\n") {
    Ok(_) => abort("corrupt state should fail")
    Err(error) => assert_true(error.contains("malformed"))
  }
}
