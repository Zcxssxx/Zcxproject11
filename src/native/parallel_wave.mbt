///|
#borrow(commands)
extern "c" fn run_parallel_ffi(
  commands : Bytes,
  command_count : Int,
  worker_count : Int,
) -> Int = "moon_ninja_run_parallel_commands"

///|
fn pack_commands(commands : Array[String]) -> Bytes {
  let mut packed = ""
  for i, command in commands {
    if i > 0 {
      packed += "\u0000"
    }
    packed += command
  }
  @utf8.encode((packed + "\u0000")[:])
}

///|
/// Run independent host commands through the native lock-free work allocator.
///
/// The C adapter uses an atomic next-index counter. Commands never mutate
/// shared MoonBit arrays, and the returned status identifies the first failed
/// command index when a worker reports failure.
pub fn run_parallel_commands(
  commands : Array[String],
  worker_count~ : Int,
) -> Result[Unit, String] {
  if commands.is_empty() {
    return Ok(())
  }
  let workers = if worker_count < 1 {
    1
  } else if worker_count > commands.length() {
    commands.length()
  } else {
    worker_count
  }
  let status = run_parallel_ffi(
    pack_commands(commands),
    commands.length(),
    workers,
  )
  if status == 0 {
    Ok(())
  } else {
    Err("native parallel command failed at index " + (-status - 1).to_string())
  }
}

///|
pub(all) struct NativeParallelWaveExecutor {
  worker_count : Int
}

///|
pub fn NativeParallelWaveExecutor::new(
  worker_count~ : Int,
) -> NativeParallelWaveExecutor {
  { worker_count, }
}

///|
pub impl @core.WaveExecutor for NativeParallelWaveExecutor with fn run_wave(
  self : NativeParallelWaveExecutor,
  edges : Array[@core.BuildEdge],
  rules : Map[String, @core.Rule],
) -> Result[Array[String], String] {
  let commands : Array[String] = []
  for edge in edges {
    match edge.render_command(rules) {
      Ok(command) => commands.push(command)
      Err(error) => return Err(error)
    }
  }
  match run_parallel_commands(commands, worker_count=self.worker_count) {
    Ok(_) => Ok(commands)
    Err(error) => Err(error)
  }
}
