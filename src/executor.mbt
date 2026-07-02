pub trait Executor {
  run(Self, BuildEdge) -> Result[Unit, String]
}
