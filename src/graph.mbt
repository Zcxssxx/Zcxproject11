pub struct DepGraph {
  nodes: Map[String, BuildEdge]
}

pub fn DepGraph::build(manifest: Manifest) -> DepGraph {
  // Topological sort logic here
  let nodes = {}
  { nodes }
}

pub fn DepGraph::traverse(self: DepGraph, target: String) -> Array[BuildEdge] {
  []
}
