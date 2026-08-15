///|
/// A read-only explanation of the dependency closure of one target.
pub(all) struct TargetInspection {
  target : String
  producer_key : String?
  direct_inputs : Array[String]
  transitive_inputs : Array[String]
  outputs : Array[String]
  leaf_inputs : Array[String]
  edge_count : Int
  depth : Int
} derive(Debug, Eq)

///|
pub fn TargetInspection::to_text(self : TargetInspection) -> String {
  let producer = match self.producer_key {
    Some(value) => value
    None => "source"
  }
  "target=" +
  self.target +
  " producer=" +
  producer +
  " edges=" +
  self.edge_count.to_string() +
  " depth=" +
  self.depth.to_string() +
  " direct_inputs=" +
  self.direct_inputs.length().to_string() +
  " transitive_inputs=" +
  self.transitive_inputs.length().to_string() +
  " leaves=" +
  self.leaf_inputs.length().to_string()
}

///|
fn inspection_unique_inputs(edges : Array[BuildEdge]) -> Array[String] {
  let inputs : Array[String] = []
  for edge in edges {
    for input in edge.inputs {
      if !inputs.contains(input) {
        inputs.push(input)
      }
    }
  }
  inputs
}

///|
fn inspection_unique_outputs(edges : Array[BuildEdge]) -> Array[String] {
  let outputs : Array[String] = []
  for edge in edges {
    for output in edge.outputs {
      if !outputs.contains(output) {
        outputs.push(output)
      }
    }
  }
  outputs
}

///|
fn inspection_leaves(edges : Array[BuildEdge]) -> Array[String] {
  let produced : Map[String, Bool] = Map([])
  for edge in edges {
    for output in edge.outputs {
      produced[output] = true
    }
  }
  let leaves : Array[String] = []
  for input in inspection_unique_inputs(edges) {
    if !produced.contains(input) {
      leaves.push(input)
    }
  }
  leaves
}

///|
/// Inspect a target without executing it. This is useful for CLI explain
/// commands, acceptance reports, and host-side scheduling decisions.
pub fn Manifest::inspect_target(
  self : Manifest,
  target : String,
) -> Result[TargetInspection, String] {
  let graph = DepGraph::build(self)
  let edges = match graph.traverse(target) {
    Err(error) => return Err(error)
    Ok(value) => value
  }
  if edges.is_empty() && !graph.producer.contains(target) {
    return Err("target is not produced: " + target)
  }
  let direct_inputs : Array[String] = match graph.producer.get(target) {
    Some(edge) => edge.inputs.copy()
    None => []
  }
  let producer_key : String? = match graph.producer.get(target) {
    Some(edge) => Some(edge.key())
    None => None
  }
  let outputs = inspection_unique_outputs(edges)
  let inputs = inspection_unique_inputs(edges)
  let leaves = inspection_leaves(edges)
  let depth = match graph.parallel_waves(target) {
    Ok(waves) => waves.length()
    Err(_) => 0
  }
  Ok({
    target,
    producer_key,
    direct_inputs,
    transitive_inputs: inputs,
    outputs,
    leaf_inputs: leaves,
    edge_count: edges.length(),
    depth,
  })
}
