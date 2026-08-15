///|
test "structured command line preserves shell argument boundaries" {
  let command = CommandLine::new(executable="cc", arguments=[
    "-Iinclude", "path with spaces.c", "-DNAME=one",
  ])
  let rendered = command.to_shell_text()
  assert_eq(rendered, "cc -Iinclude \"path with spaces.c\" -DNAME=one")
  assert_true(command.has_unsafe_argument())
}

///|
test "structured command line round trips through response text" {
  let command = CommandLine::new(executable="clang", arguments=[
    "-O2", "path with spaces.c", "-o", "build/app",
  ])
  match command_line_from_text(command.to_shell_text()) {
    Err(error) => abort(error)
    Ok(restored) => assert_true(restored == command)
  }
  assert_true(command.to_response_file().contains("path with spaces.c"))
}

///|
test "structured command line rejects empty input and supports append" {
  match command_line_from_text("") {
    Ok(_) => abort("empty command should fail")
    Err(error) => assert_true(error.contains("empty"))
  }
  let command = CommandLine::new(executable="cc", arguments=[]).append("-Wall")
  assert_true(command.arguments == ["-Wall"])
}
