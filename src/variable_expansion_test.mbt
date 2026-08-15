///|
test "variable expansion resolves Ninja command variables" {
  let context = ExpansionContext::new(
    inputs=["src/main.c", "src/util.c"],
    outputs=["build/app"],
    variables={ "mode": "debug", "cc": "clang" },
  )
  assert_eq(
    expand_command("$cc -D$mode $in -o $out", context),
    "clang -Ddebug src/main.c src/util.c -o build/app",
  )
}

///|
test "variable expansion supports newline inputs and escaped dollars" {
  let context = ExpansionContext::new(
    inputs=["one.c", "two.c"],
    outputs=["all.o"],
    variables=Map([]),
  )
  assert_eq(expand_command("$in_newline", context), "one.c\ntwo.c")
  assert_eq(expand_command("$$in $missing", context), "$in ")
}

///|
test "variable expansion rejects recursive variables" {
  let context = ExpansionContext::new(inputs=[], outputs=[], variables={
    "a": "$b",
    "b": "$a",
  })
  match expand_command_checked("$a", context) {
    Ok(_) => abort("recursive variables should fail")
    Err(message) => assert_true(message.contains("recursive"))
  }
}

///|
test "edge command rendering accepts named variables" {
  let edge : BuildEdge = { rule: "cc", inputs: ["main.c"], outputs: ["main.o"] }
  let rules : Map[String, Rule] = {
    "cc": { name: "cc", command: "$cc -D$mode $in -o $out" },
  }
  match
    edge.render_command_with_variables(rules, { "cc": "gcc", "mode": "release" }) {
    Ok(command) => assert_eq(command, "gcc -Drelease main.c -o main.o")
    Err(error) => abort(error)
  }
}
