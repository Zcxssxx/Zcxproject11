fn main {
  let manifest : @src.Manifest = { rules: {}, builds: [] }
  let graph = @src.DepGraph::build(manifest)
  let executor = @src.LocalExecutor::{}
  let scheduler = @src.Scheduler::{ graph, executor }
  let _ = scheduler.run_all()
  let rule = @src.Rule::{ name: "cc", command: "gcc" }
  let _ = rule
  let build_edge = @src.BuildEdge::{ rule: "cc", inputs: [], outputs: [] }
  let _ = build_edge
  println("MoonNinja build system initialized.")
}
