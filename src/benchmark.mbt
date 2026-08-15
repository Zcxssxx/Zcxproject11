///|
pub(all) struct BenchmarkSummary {
  rule_count : Int
  edge_count : Int
  node_count : Int
  dependency_depth : Int
  wave_count : Int
  max_wave_width : Int
  critical_path : Int
  fan_in : Int
  fanout : Int
  command_count : Int
} derive(Debug, Eq)

///|
pub(all) struct BenchmarkReport {
  summary : BenchmarkSummary
  rendered_commands : Array[String]
  wave_sizes : Array[Int]
} derive(Debug)

///|
pub fn BenchmarkSummary::to_text(self : BenchmarkSummary) -> String {
  "rules=" +
  self.rule_count.to_string() +
  " edges=" +
  self.edge_count.to_string() +
  " nodes=" +
  self.node_count.to_string() +
  " depth=" +
  self.dependency_depth.to_string() +
  " waves=" +
  self.wave_count.to_string() +
  " max_wave_width=" +
  self.max_wave_width.to_string() +
  " critical_path=" +
  self.critical_path.to_string() +
  " fan_in=" +
  self.fan_in.to_string() +
  " fanout=" +
  self.fanout.to_string() +
  " commands=" +
  self.command_count.to_string()
}

///|
fn benchmark_nodes(edges : Array[BuildEdge]) -> Map[String, Bool] {
  let nodes : Map[String, Bool] = Map([])
  for edge in edges {
    for input in edge.inputs {
      nodes[input] = true
    }
    for output in edge.outputs {
      nodes[output] = true
    }
  }
  nodes
}

///|
fn benchmark_fan_in(edges : Array[BuildEdge]) -> Int {
  let mut total = 0
  for edge in edges {
    total += edge.inputs.length()
  }
  if edges.is_empty() {
    0
  } else {
    total / edges.length()
  }
}

///|
fn benchmark_fanout(edges : Array[BuildEdge]) -> Int {
  let producers : Map[String, Int] = Map([])
  for edge in edges {
    for input in edge.inputs {
      producers[input] = match producers.get(input) {
        Some(value) => value + 1
        None => 1
      }
    }
  }
  let mut highest = 0
  for _, count in producers {
    if count > highest {
      highest = count
    }
  }
  highest
}

///|
/// Measure a target's real parsed graph, not a synthetic line-count metric.
pub fn Manifest::benchmark(
  self : Manifest,
  target : String,
) -> Result[BenchmarkReport, String] {
  let mut target_is_output = false
  for edge in self.builds {
    if edge.outputs.contains(target) {
      target_is_output = true
    }
  }
  if !target_is_output {
    return Err("benchmark target is not produced: " + target)
  }
  match self.validate() {
    Err(error) => Err(error)
    Ok(_) =>
      match DepGraph::build(self).parallel_waves(target) {
        Err(error) => Err(error)
        Ok(waves) => {
          let edges = match DepGraph::build(self).traverse(target) {
            Ok(value) => value
            Err(error) => return Err(error)
          }
          let rendered_commands : Array[String] = []
          for edge in edges {
            match edge.render_command(self.rules) {
              Ok(command) => rendered_commands.push(command)
              Err(error) => return Err(error)
            }
          }
          let wave_sizes : Array[Int] = []
          let mut max_wave_width = 0
          for wave in waves {
            wave_sizes.push(wave.length())
            if wave.length() > max_wave_width {
              max_wave_width = wave.length()
            }
          }
          let summary : BenchmarkSummary = {
            rule_count: self.rules.length(),
            edge_count: edges.length(),
            node_count: benchmark_nodes(edges).length(),
            dependency_depth: waves.length(),
            wave_count: waves.length(),
            max_wave_width,
            critical_path: waves.length(),
            fan_in: benchmark_fan_in(edges),
            fanout: benchmark_fanout(edges),
            command_count: rendered_commands.length(),
          }
          Ok({ summary, rendered_commands, wave_sizes })
        }
      }
  }
}

///|
pub fn benchmark_from_ninja(
  input : String,
  target : String,
) -> Result[BenchmarkReport, String] {
  try {
    let manifest = Parser::new(input).parse()
    manifest.benchmark(target)
  } catch {
    ParseError::SyntaxError(message, line~, col~) =>
      Err(
        "parse error at " +
        line.to_string() +
        ":" +
        col.to_string() +
        ": " +
        message,
      )
    ParseError::UnexpectedToken(token, expected~) =>
      Err("unexpected token " + token.to_string() + ", expected " + expected)
  }
}

///|
/// Build a repeatable multi-layer workload for performance and boundary tests.
pub fn synthetic_fixture(layer_count~ : Int, fanout~ : Int) -> Manifest {
  let layers = if layer_count < 1 { 1 } else { layer_count }
  let width = if fanout < 1 { 1 } else { fanout }
  let builds : Array[BuildEdge] = []
  for layer in 0..<layers {
    for branch in 0..<width {
      let inputs : Array[String] = if layer == 0 {
        ["fixture_source_" + branch.to_string() + ".c"]
      } else {
        let previous : Array[String] = []
        for previous_branch in 0..<width {
          previous.push(
            "fixture_l" +
            (layer - 1).to_string() +
            "_" +
            previous_branch.to_string() +
            ".o",
          )
        }
        previous
      }
      builds.push({
        rule: "compile",
        inputs,
        outputs: [
          "fixture_l" + layer.to_string() + "_" + branch.to_string() + ".o",
        ],
      })
    }
  }
  let final_inputs : Array[String] = []
  for branch in 0..<width {
    final_inputs.push(
      "fixture_l" + (layers - 1).to_string() + "_" + branch.to_string() + ".o",
    )
  }
  builds.push({ rule: "compile", inputs: final_inputs, outputs: ["artifact"] })
  {
    rules: {
      "compile": { name: "compile", command: "echo compile $in -o $out" },
    },
    builds,
  }
}
