///|
pub(all) struct DepGraph {
  nodes : Map[String, BuildEdge]
  rules : Map[String, Rule]
  producer : Map[String, BuildEdge]
}

///|
pub fn DepGraph::build(manifest : Manifest) -> DepGraph {
  let nodes : Map[String, BuildEdge] = Map([])
  let producer : Map[String, BuildEdge] = Map([])
  for edge in manifest.builds {
    nodes[edge.key()] = edge
    for out in edge.outputs {
      producer[out] = edge
    }
  }
  { nodes, rules: manifest.rules, producer }
}

///|
fn DepGraph::all_nodes(self : DepGraph) -> Array[String] {
  let result : Array[String] = []
  for _, edge in self.nodes {
    for input in edge.inputs {
      if !result.contains(input) {
        result.push(input)
      }
    }
    for output in edge.outputs {
      if !result.contains(output) {
        result.push(output)
      }
    }
  }
  result
}

///|
fn DepGraph::neighbors(self : DepGraph, node : String) -> Array[String] {
  match self.producer.get(node) {
    Some(edge) => edge.inputs
    None => []
  }
}

///|
fn DepGraph::has_self_loop(self : DepGraph, node : String) -> Bool {
  for input in self.neighbors(node) {
    if input == node {
      return true
    }
  }
  false
}

///|
/// Return all strongly connected components using Tarjan's algorithm.
pub fn DepGraph::strongly_connected_components(
  self : DepGraph,
) -> Array[Array[String]] {
  let indices : Map[String, Int] = Map([])
  let lowlinks : Map[String, Int] = Map([])
  let on_stack : Map[String, Bool] = Map([])
  let stack : Array[String] = []
  let components : Array[Array[String]] = []
  let mut next_index = 0

  fn visit(node : String) -> Unit {
    indices[node] = next_index
    lowlinks[node] = next_index
    next_index += 1
    stack.push(node)
    on_stack[node] = true

    for neighbor in self.neighbors(node) {
      match indices.get(neighbor) {
        None => {
          visit(neighbor)
          let neighbor_lowlink = lowlinks[neighbor]
          if neighbor_lowlink < lowlinks[node] {
            lowlinks[node] = neighbor_lowlink
          }
        }
        Some(neighbor_index) =>
          if on_stack.get(neighbor) is Some(true) &&
            neighbor_index < lowlinks[node] {
            lowlinks[node] = neighbor_index
          }
      }
    }

    if lowlinks[node] == indices[node] {
      let component : Array[String] = []
      let mut done = false
      while !done {
        match stack.pop() {
          Some(item) => {
            on_stack[item] = false
            component.push(item)
            if item == node {
              done = true
            }
          }
          None => done = true
        }
      }
      components.push(component)
    }
  }

  for node in self.all_nodes() {
    if !indices.contains(node) {
      visit(node)
    }
  }
  components
}

///|
fn DepGraph::reachable_from(
  self : DepGraph,
  target : String,
) -> Map[String, Bool] {
  let reachable : Map[String, Bool] = Map([])

  fn visit(node : String) -> Unit {
    if reachable.contains(node) {
      return
    }
    reachable[node] = true
    for neighbor in self.neighbors(node) {
      visit(neighbor)
    }
  }

  visit(target)
  reachable
}

///|
fn format_cycle(component : Array[String]) -> String {
  "Circular dependency detected in SCC: [" + join_strings(component, ", ") + "]"
}

///|
/// Return dependency edges grouped into deterministic, lock-free waves.
pub fn DepGraph::parallel_waves(
  self : DepGraph,
  target : String,
) -> Result[Array[Array[BuildEdge]], String] {
  match self.traverse(target) {
    Err(error) => Err(error)
    Ok(edges) => {
      let depth : Map[String, Int] = Map([])
      let waves : Array[Array[BuildEdge]] = []
      for edge in edges {
        let mut wave_index = 0
        for input in edge.inputs {
          match depth.get(input) {
            Some(input_depth) =>
              if input_depth + 1 > wave_index {
                wave_index = input_depth + 1
              }
            None => ()
          }
        }
        while waves.length() <= wave_index {
          waves.push([])
        }
        waves[wave_index].push(edge)
        for output in edge.outputs {
          depth[output] = wave_index
        }
      }
      Ok(waves)
    }
  }
}

///|
pub fn DepGraph::traverse(
  self : DepGraph,
  target : String,
) -> Result[Array[BuildEdge], String] {
  let reachable = self.reachable_from(target)
  for component in self.strongly_connected_components() {
    let cyclic = component.length() > 1 ||
      (component.length() == 1 && self.has_self_loop(component[0]))
    if cyclic {
      for item in component {
        if reachable.contains(item) {
          return Err(format_cycle(component))
        }
      }
    }
  }

  let result : Array[BuildEdge] = []
  let visiting : Map[String, Bool] = Map([])
  let visited : Map[String, Bool] = Map([])
  let scheduled : Map[String, Bool] = Map([])

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
        let edge_key = edge.key()
        if !scheduled.contains(edge_key) {
          result.push(edge)
          scheduled[edge_key] = true
        }
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
