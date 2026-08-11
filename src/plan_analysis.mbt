///|
pub(all) struct PlanAnalysis {
  target : String
  edge_count : Int
  wave_count : Int
  critical_path : Int
  max_parallelism : Int
  leaf_input_count : Int
  produced_output_count : Int
  leaf_inputs : Array[String]
} derive(Debug, Eq)

///|
pub fn PlanAnalysis::to_text(self : PlanAnalysis) -> String {
  "target=" +
  self.target +
  " edges=" +
  self.edge_count.to_string() +
  " waves=" +
  self.wave_count.to_string() +
  " critical_path=" +
  self.critical_path.to_string() +
  " max_parallelism=" +
  self.max_parallelism.to_string() +
  " leaves=" +
  self.leaf_input_count.to_string() +
  " outputs=" +
  self.produced_output_count.to_string()
}

///|
/// Analyze the executable shape of one target before choosing a host runner.
pub fn DepGraph::analyze(
  self : DepGraph,
  target : String,
) -> Result[PlanAnalysis, String] {
  let edges = match self.traverse(target) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let waves = match self.parallel_waves(target) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let produced : Map[String, Bool] = Map([])
  for edge in edges {
    for output in edge.outputs {
      produced[output] = true
    }
  }
  let leaves : Map[String, Bool] = Map([])
  for edge in edges {
    for input in edge.inputs {
      if !produced.contains(input) {
        leaves[input] = true
      }
    }
  }
  let leaf_inputs : Array[String] = []
  for input, _ in leaves {
    leaf_inputs.push(input)
  }
  let mut max_parallelism = 0
  for wave in waves {
    if wave.length() > max_parallelism {
      max_parallelism = wave.length()
    }
  }
  Ok({
    target,
    edge_count: edges.length(),
    wave_count: waves.length(),
    critical_path: waves.length(),
    max_parallelism,
    leaf_input_count: leaf_inputs.length(),
    produced_output_count: produced.length(),
    leaf_inputs,
  })
}

///|
pub fn Manifest::analyze(
  self : Manifest,
  target : String,
) -> Result[PlanAnalysis, String] {
  DepGraph::build(self).analyze(target)
}
