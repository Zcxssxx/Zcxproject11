pub(all) struct DepGraph {
  nodes: Map[String, BuildEdge]
}

pub fn DepGraph::build(manifest: Manifest) -> DepGraph {
  let _ = manifest
  let nodes = {}
  { nodes, }
}

pub fn DepGraph::traverse(self: DepGraph, target: String) -> Array[BuildEdge] {
  let _ = self
  let _ = target
  []
}
