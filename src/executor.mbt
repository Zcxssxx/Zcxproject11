pub trait Executor {
  run(Self, BuildEdge, Map[String, Rule]) -> Result[Unit, String]
}
