///|
/// A runner supplied by the host for one independent dependency wave.
///
/// The graph planner never shares a mutable ready queue between waves. A
/// native caller can implement this trait with a thread pool, while a WASM
/// caller can dispatch the whole wave to its host scheduler.
pub(open) trait WaveExecutor {
  fn run_wave(Self, Array[BuildEdge], Map[String, Rule]) -> Result[
    Array[String],
    String,
  ]
}

///|
pub(all) struct DryRunWaveExecutor {}

///|
pub impl WaveExecutor for DryRunWaveExecutor with fn run_wave(
  self : DryRunWaveExecutor,
  edges : Array[BuildEdge],
  rules : Map[String, Rule],
) -> Result[Array[String], String] {
  let _ = self
  let commands : Array[String] = []
  for edge in edges {
    match edge.render_command(rules) {
      Ok(command) => commands.push(command)
      Err(error) => return Err(error)
    }
  }
  Ok(commands)
}

///|
/// Execute independent waves without a shared mutable queue or lock.
pub fn[E : WaveExecutor] Scheduler::run_parallel_waves(
  self : Scheduler[E],
  target : String,
) -> Result[Array[String], String] {
  let commands : Array[String] = []
  match self.graph.parallel_waves(target) {
    Err(error) => Err(error)
    Ok(waves) => {
      for wave in waves {
        match self.executor.run_wave(wave, self.graph.rules) {
          Ok(wave_commands) =>
            for command in wave_commands {
              commands.push(command)
            }
          Err(error) => return Err(error)
        }
      }
      Ok(commands)
    }
  }
}
