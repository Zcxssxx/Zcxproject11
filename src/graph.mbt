pub(all) struct DepGraph {
  nodes: Map[String, BuildEdge]
  rules: Map[String, Rule]
  producer: Map[String, BuildEdge]
}

pub fn DepGraph::build(manifest: Manifest) -> DepGraph {
  let producer : Map[String, BuildEdge] = {}
  for edge in manifest.builds {
    for out in edge.outputs {
      producer[out] = edge
    }
  }
  { nodes: {}, rules: manifest.rules, producer }
}

pub fn DepGraph::traverse(self: DepGraph, target: String) -> Result[Array[BuildEdge], String] {
  let result : Array[BuildEdge] = []
  let visiting : Map[String, Bool] = {}
  let visited : Map[String, Bool] = {}
  
  fn dfs(node : String) -> Result[Unit, String] {
    if visiting.contains(node) {
      return Err("Circular dependency detected at: " + node)
    }
    if visited.contains(node) {
      return Ok(())
    }
    visiting[node] = true
    let edge_opt : BuildEdge? = self.producer.get(node)
    match edge_opt {
      Some(edge) => {
        for input in edge.inputs {
          match dfs(input) {
            Ok(_) => ()
            Err(e) => return Err(e)
          }
        }
        result.push(edge)
      }
      None => ()
    }
    visiting.remove(node)
    visited[node] = true
    Ok(())
  }
  
  match dfs(target) {
    Ok(_) => Ok(result)
    Err(e) => Err(e)
  }
}
