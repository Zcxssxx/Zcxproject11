pub(all) struct Scheduler[E] {
  graph: DepGraph
  executor: E
}

pub fn[E : Executor] Scheduler::run_all(self: Scheduler[E], target: String) -> Result[Unit, String] {
  match self.graph.traverse(target) {
    Ok(edges) => {
      for edge in edges {
        match self.executor.run(edge, self.graph.rules) {
          Ok(_) => ()
          Err(e) => return Err(e)
        }
      }
      Ok(())
    }
    Err(e) => Err(e)
  }
}
