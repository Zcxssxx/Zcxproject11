///|
pub(all) struct Scheduler[E] {
  graph : DepGraph
  executor : E
}

///|
pub fn[E] Scheduler::plan(
  self : Scheduler[E],
  target : String,
) -> Result[Array[BuildEdge], String] {
  self.graph.traverse(target)
}

///|
pub fn[E : Executor] Scheduler::run_all(
  self : Scheduler[E],
  target : String,
) -> Result[Unit, String] {
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

///|
pub fn[E : Executor] Scheduler::run_incremental(
  self : Scheduler[E],
  target : String,
  snapshot : Map[String, Int],
) -> Result[Array[String], String] {
  let executed : Array[String] = []
  let mut tick = 1
  match self.graph.traverse(target) {
    Ok(edges) => {
      for edge in edges {
        match edge.evaluate_incremental(snapshot) {
          UpToDate => ()
          NeedsBuild(_) => {
            match edge.render_command(self.graph.rules) {
              Ok(cmd) => executed.push(cmd)
              Err(e) => return Err(e)
            }
            match self.executor.run(edge, self.graph.rules) {
              Ok(_) => tick = edge.refresh_outputs(snapshot, tick)
              Err(e) => return Err(e)
            }
          }
        }
      }
      Ok(executed)
    }
    Err(e) => Err(e)
  }
}
