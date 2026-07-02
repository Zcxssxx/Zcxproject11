pub(all) struct LocalExecutor {}

pub impl Executor for LocalExecutor with run(self : LocalExecutor, edge : BuildEdge) -> Result[Unit, String] {
  let _ = self
  let _ = edge
  Ok(())
}
