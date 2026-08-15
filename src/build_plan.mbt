///|
/// A fully materialized, deterministic plan for one requested target.
/// Unlike a scheduler, this value is safe to inspect, serialize, benchmark,
/// or hand to a native/WASM host before any command is executed.
pub(all) struct MaterializedPlan {
  target : String
  edges : Array[BuildEdge]
  waves : Array[Array[BuildEdge]]
  commands : Array[String]
  inputs : Array[String]
  outputs : Array[String]
  critical_path : Int
} derive(Debug, Eq)

///|
pub fn MaterializedPlan::to_text(self : MaterializedPlan) -> String {
  "target=" +
  self.target +
  " edges=" +
  self.edges.length().to_string() +
  " waves=" +
  self.waves.length().to_string() +
  " critical_path=" +
  self.critical_path.to_string() +
  " inputs=" +
  self.inputs.length().to_string() +
  " outputs=" +
  self.outputs.length().to_string() +
  " commands=" +
  self.commands.length().to_string()
}

///|
fn plan_has_duplicate_output(edges : Array[BuildEdge]) -> String? {
  let producers : Map[String, String] = Map([])
  for edge in edges {
    for output in edge.outputs {
      match producers.get(output) {
        Some(previous) =>
          return Some(
            "duplicate output producer: " +
            output +
            " from " +
            previous +
            " and " +
            edge.key(),
          )
        None => producers[output] = edge.key()
      }
    }
  }
  None
}

///|
fn plan_unique_values(
  edges : Array[BuildEdge],
  output_mode : Bool,
) -> Array[String] {
  let values : Array[String] = []
  for edge in edges {
    let candidates = if output_mode { edge.outputs } else { edge.inputs }
    for item in candidates {
      if !values.contains(item) {
        values.push(item)
      }
    }
  }
  values
}

///|
fn plan_leaf_inputs(edges : Array[BuildEdge]) -> Array[String] {
  let produced : Map[String, Bool] = Map([])
  for edge in edges {
    for output in edge.outputs {
      produced[output] = true
    }
  }
  let leaves : Array[String] = []
  for edge in edges {
    for input in edge.inputs {
      if !produced.contains(input) && !leaves.contains(input) {
        leaves.push(input)
      }
    }
  }
  leaves
}

///|
/// Materialize one target with stable traversal order and explicit variables.
pub fn Manifest::materialize_plan(
  self : Manifest,
  target : String,
  variables : Map[String, String],
) -> Result[MaterializedPlan, String] {
  let produced : Map[String, Bool] = Map([])
  for edge in self.builds {
    for output in edge.outputs {
      produced[output] = true
    }
  }
  if !produced.contains(target) {
    return Err("target is not produced: " + target)
  }
  match plan_has_duplicate_output(self.builds) {
    Some(error) => return Err(error)
    None => ()
  }
  match self.validate() {
    Err(error) => Err(error)
    Ok(_) => {
      let graph = DepGraph::build(self)
      let edges = match graph.traverse(target) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let waves = match graph.parallel_waves(target) {
        Err(error) => return Err(error)
        Ok(value) => value
      }
      let commands : Array[String] = []
      for edge in edges {
        match edge.render_command_with_variables(self.rules, variables) {
          Err(error) => return Err(error)
          Ok(command) => commands.push(command)
        }
      }
      Ok({
        target,
        edges,
        waves,
        commands,
        inputs: plan_leaf_inputs(edges),
        outputs: plan_unique_values(edges, true),
        critical_path: waves.length(),
      })
    }
  }
}
