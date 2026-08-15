///|
test "dependency diff identifies added removed and unchanged paths" {
  let diff = compare_dependencies("app", ["main.c", "old.h", "common.h"], [
    "main.c", "new.h", "common.h", "new.h",
  ])
  assert_true(diff.added == ["new.h"])
  assert_true(diff.removed == ["old.h"])
  assert_true(diff.unchanged == ["main.c", "common.h"])
  assert_true(diff.to_text().contains("target=app"))
}

///|
test "dependency diff is stable for duplicate inputs" {
  let diff = compare_dependencies("app", ["a", "a"], ["a", "a"])
  assert_true(diff.added.is_empty())
  assert_true(diff.removed.is_empty())
  assert_true(diff.unchanged == ["a"])
}
