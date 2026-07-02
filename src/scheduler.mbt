pub(all) struct Scheduler[E] {
  graph: DepGraph
  executor: E
}

pub fn[E : Executor] Scheduler::run_all(self: Scheduler[E]) -> Result[Unit, String] {
  let dummy_edge = BuildEdge::{ rule: "", inputs: [], outputs: [] }
  let _ = self.executor.run(dummy_edge)
  let _ = self.graph
  Ok(())
}
