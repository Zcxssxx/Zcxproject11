///|
pub(all) struct LocalExecutor {}

///|
pub impl Executor for LocalExecutor with fn run(
  self : LocalExecutor,
  edge : BuildEdge,
  rules : Map[String, Rule],
) -> Result[Unit, String] {
  let _ = self
  match edge.render_command(rules) {
    Ok(cmd) => {
      println("Executing: " + cmd)
      let exit_code = execute_command(cmd)
      if exit_code == 0 {
        Ok(())
      } else {
        Err("Command failed with exit code: " + exit_code.to_string())
      }
    }
    Err(e) => Err(e)
  }
}
