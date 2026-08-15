///|
fn plan_fixture() -> Manifest {
  {
    rules: { "cc": { name: "cc", command: "cc $in -o $out" } },
    builds: [
      { rule: "cc", inputs: ["one.c"], outputs: ["one.o"] },
      { rule: "cc", inputs: ["two.c"], outputs: ["two.o"] },
      { rule: "cc", inputs: ["one.o", "two.o"], outputs: ["app"] },
    ],
  }
}

///|
test "materialized plan exposes stable waves and commands" {
  match plan_fixture().materialize_plan("app", Map([])) {
    Ok(plan) => {
      assert_eq(plan.waves.length(), 2)
      assert_eq(plan.waves[0].length(), 2)
      assert_true(
        plan.commands ==
        ["cc one.c -o one.o", "cc two.c -o two.o", "cc one.o two.o -o app"],
      )
      assert_eq(plan.target, "app")
      assert_true(plan.to_text().contains("critical_path=2"))
    }
    Err(error) => abort(error)
  }
}

///|
test "materialized plan reports missing targets" {
  match plan_fixture().materialize_plan("missing", Map([])) {
    Ok(_) => abort("missing target should fail")
    Err(error) => assert_true(error.contains("not produced"))
  }
}

///|
test "materialized plan rejects duplicate producers" {
  let manifest = {
    ..plan_fixture(),
    builds: [
      { rule: "cc", inputs: ["one.c"], outputs: ["same.o"] },
      { rule: "cc", inputs: ["two.c"], outputs: ["same.o"] },
    ],
  }
  match manifest.materialize_plan("same.o", Map([])) {
    Ok(_) => abort("duplicate producers should fail")
    Err(error) => assert_true(error.contains("duplicate"))
  }
}

///|
test "benchmark includes materialized plan metrics" {
  match plan_fixture().benchmark("app") {
    Ok(report) => {
      assert_eq(report.summary.wave_count, 2)
      assert_true(report.summary.critical_path >= 2)
    }
    Err(error) => abort(error)
  }
}
