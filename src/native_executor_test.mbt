///|
#cfg(target="native")
test "native executor runs a real host command" {
  let edge : BuildEdge = {
    rule: "echo",
    inputs: [],
    outputs: ["native-test-output"],
  }
  let rules : Map[String, Rule] = {
    "echo": { name: "echo", command: "exit 0" },
  }
  let executor = LocalExecutor::{  }
  match executor.run(edge, rules) {
    Ok(_) => ()
    Err(error) => abort("Native executor failed: " + error)
  }
}
