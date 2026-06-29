pub trait Executor {
  run(self, edge: BuildEdge) -> Result[Unit, String]
}
