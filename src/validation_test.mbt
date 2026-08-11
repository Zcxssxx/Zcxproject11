///|
fn validation_manifest() -> Manifest {
  {
    rules: { "cc": { name: "cc", command: "gcc -c $in -o $out" } },
    builds: [
      { rule: "missing", inputs: ["input.c"], outputs: ["missing.o"] },
      { rule: "cc", inputs: [], outputs: [] },
      { rule: "cc", inputs: ["input.c"], outputs: ["duplicate.o"] },
      { rule: "cc", inputs: ["other.c"], outputs: ["duplicate.o"] },
    ],
  }
}

///|
test "validation reports unknown rule and empty outputs" {
  let issues = validation_manifest().validation_issues()
  assert_true(issues.length() >= 3)
  assert_true(issues.any(issue => issue.code == "unknown-rule"))
  assert_true(issues.any(issue => issue.code == "empty-outputs"))
  assert_true(issues.any(issue => issue.code == "duplicate-output"))
}

///|
test "validation distinguishes warnings from errors" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [{ rule: "cc", inputs: [], outputs: ["stamp"] }],
  }
  let issues = manifest.validation_issues()
  assert_true(
    issues.any(issue => issue.severity == ValidationSeverity::Warning),
  )
  assert_true(manifest.is_valid())
}

///|
test "validation rejects a completely empty manifest" {
  let manifest : Manifest = { rules: {}, builds: [] }
  let issues = manifest.validation_issues()
  assert_true(issues.any(issue => issue.code == "empty-manifest"))
  assert_false(manifest.is_valid())
}

///|
test "parser rejects duplicate rule names with an actionable error" {
  let parser = Parser::new(
    (
      #|rule cc
      #|  command = first $in
      #|rule cc
      #|  command = second $in
      #|build out: cc input
      #|,
    ),
  )
  try {
    ignore(parser.parse())
    abort("duplicate rule should be rejected")
  } catch {
    ParseError::SyntaxError(message, ..) =>
      assert_true(message.contains("Duplicate rule"))
    _ => abort("duplicate rule should report a syntax error")
  }
}

///|
test "validation accepts a small complete manifest" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "gcc -c $in -o $out" } },
    builds: [{ rule: "cc", inputs: ["input.c"], outputs: ["output.o"] }],
  }
  assert_true(manifest.validation_issues().is_empty())
  assert_true(manifest.is_valid())
}
