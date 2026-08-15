///|
test "command validation accepts ordinary compiler arguments" {
  let command = CommandLine::new(executable="cc", arguments=["-O2", "main.c"])
  assert_true(command.is_valid())
  assert_true(command.validate().is_empty())
}

///|
test "command validation reports unsafe structure" {
  let command = CommandLine::new(executable="cc compiler", arguments=[
    "", "line\nbreak",
  ])
  let issues = command.validate()
  assert_eq(issues.length(), 3)
  assert_true(issues[0].code == "split-executable")
  assert_true(issues[1].code == "empty-argument")
  assert_true(issues[2].to_text().contains("newline-argument"))
}
