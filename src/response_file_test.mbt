///|
test "response file parser preserves quoted arguments" {
  match
    parse_response_file("-Iinclude \"path with spaces\" -DNAME=one\\ two\n") {
    Ok(args) => {
      assert_eq(args.length(), 3)
      assert_eq(args[0], "-Iinclude")
      assert_eq(args[1], "path with spaces")
      assert_eq(args[2], "-DNAME=one two")
    }
    Err(error) => abort(error)
  }
}

///|
test "response file parser handles comments and empty files" {
  match parse_response_file("# generated flags\n-Iinclude\n\n") {
    Ok(args) => assert_true(args == ["-Iinclude"])
    Err(error) => abort(error)
  }
  match parse_response_file("") {
    Ok(args) => assert_true(args.is_empty())
    Err(error) => abort(error)
  }
}

///|
test "response file parser reports unterminated quotes" {
  match parse_response_file("-DNAME=\"broken\n") {
    Ok(_) => abort("unterminated quote should fail")
    Err(error) => assert_true(error.contains("quote"))
  }
}

///|
test "command materializer expands response file references" {
  let files = { "flags.rsp": "-O2 \"path with spaces\"" }
  match materialize_response_command("cc @flags.rsp -o app", files) {
    Ok(command) =>
      assert_true(command == ["cc", "-O2", "path with spaces", "-o", "app"])
    Err(error) => abort(error)
  }
}
