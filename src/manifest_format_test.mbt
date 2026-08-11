///|
test "manifest formatter emits a parseable Ninja subset" {
  let original : Manifest = {
    rules: {
      "cc": { name: "cc", command: "gcc -c $in -o $out" },
      "link": { name: "link", command: "gcc $in -o $out" },
    },
    builds: [
      { rule: "cc", inputs: ["main.c"], outputs: ["main.o"] },
      { rule: "link", inputs: ["main.o"], outputs: ["app"] },
    ],
  }
  let text = original.to_ninja()
  assert_true(text.contains("rule cc"))
  assert_true(text.contains("build app: link main.o"))
  try {
    let parsed = Parser::new(text).parse()
    assert_eq(parsed.rules.length(), 2)
    assert_eq(parsed.builds.length(), 2)
  } catch {
    _ => abort("formatted manifest should parse")
  }
}

///|
test "manifest formatter preserves multiple outputs and command placeholders" {
  let manifest : Manifest = {
    rules: { "archive": { name: "archive", command: "ar rcs $out $in" } },
    builds: [
      {
        rule: "archive",
        inputs: ["one.o", "two.o", "three.o"],
        outputs: ["libone.a", "libtwo.a"],
      },
    ],
  }
  let text = manifest.to_ninja()
  assert_true(
    text.contains("build libone.a libtwo.a: archive one.o two.o three.o"),
  )
  assert_true(text.contains("ar rcs $out $in"))
}

///|
test "formatter handles empty rule and build collections explicitly" {
  let manifest : Manifest = { rules: {}, builds: [] }
  assert_eq(manifest.to_ninja(), "# MoonNinja generated manifest\n")
}
