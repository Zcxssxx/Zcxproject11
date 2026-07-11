///|
pub trait Executor {
  fn run(Self, BuildEdge, Map[String, Rule]) -> Result[Unit, String]
}
