///|
test "depfile parser handles escaped paths and line continuations" {
  let input =
    #|build/app: src/main.c src/space\ file.c \
    #|  generated/config\:debug.h
    #|
  match parse_depfile(input) {
    Ok(depfile) => {
      assert_eq(depfile.target, "build/app")
      assert_eq(depfile.dependencies.length(), 3)
      assert_true(depfile.dependencies.contains("src/space file.c"))
      assert_true(depfile.dependencies.contains("generated/config:debug.h"))
    }
    Err(error) => abort(error)
  }
}

///|
test "depfile parser deduplicates dependencies deterministically" {
  match parse_depfile("app: a.h b.h a.h b.h\n") {
    Ok(depfile) => assert_true(depfile.dependencies == ["a.h", "b.h"])
    Err(error) => abort(error)
  }
}

///|
test "depfile parser rejects missing separator and target" {
  match parse_depfile("not a depfile\n") {
    Ok(_) => abort("malformed depfile should fail")
    Err(error) => assert_true(error.contains("target") || error.contains(":"))
  }
  match parse_depfile(": dependency.h\n") {
    Ok(_) => abort("empty target should fail")
    Err(error) => assert_true(error.contains("target"))
  }
}

///|
test "depfile application adds only missing dependencies to an edge" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "cc -c $in -o $out" } },
    builds: [{ rule: "cc", inputs: ["main.c"], outputs: ["main.o"] }],
  }
  let depfile = Depfile::{
    target: "main.o",
    dependencies: ["main.c", "config.h"],
  }
  match manifest.apply_depfile(depfile) {
    Ok(updated) =>
      assert_true(updated.builds[0].inputs == ["main.c", "config.h"])
    Err(error) => abort(error)
  }
}
