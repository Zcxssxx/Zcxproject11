///|
test "validation diagnostics carry repair hints" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [{ rule: "missing", inputs: ["a.c"], outputs: ["a.o"] }],
  }
  let diagnostics = manifest.diagnostics_for_manifest()
  assert_true(diagnostics.length() == 1)
  assert_eq(diagnostics[0].code, "unknown-rule")
  assert_true(diagnostics[0].hint.contains("declare"))
  assert_true(
    diagnostics_text(diagnostics).contains("validation[unknown-rule]"),
  )
}

///|
test "diagnostics convert syntax errors without losing location" {
  let parser = Parser::new(
    (
      #|rule cc
      #|  command nope
      #|,
    ),
  )
  try {
    ignore(parser.parse())
    abort("malformed command should fail")
  } catch {
    error => {
      let diagnostic = diagnostics_for_parse(error)
      assert_eq(diagnostic.kind, DiagnosticKind::Parse)
      assert_eq(diagnostic.code, "syntax-error")
      assert_true(diagnostic.subject.contains(":"))
      assert_true(diagnostic.hint.contains("command"))
    }
  }
}

///|
test "graph diagnostics identify strongly connected components" {
  let diagnostic = diagnostics_for_graph(
    "Circular dependency detected in SCC: [a, b]",
  )
  assert_eq(diagnostic.kind, DiagnosticKind::Graph)
  assert_eq(diagnostic.code, "cycle")
  assert_true(diagnostic.to_text().contains("dependency graph"))
}

///|
test "valid manifests produce no validation diagnostics" {
  let manifest : Manifest = {
    rules: { "cc": { name: "cc", command: "echo $in -> $out" } },
    builds: [{ rule: "cc", inputs: ["a.c"], outputs: ["a.o"] }],
  }
  assert_true(manifest.diagnostics_for_manifest().is_empty())
}
