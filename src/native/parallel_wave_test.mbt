///|
#cfg(target="native")
test "native parallel wave runs real host commands" {
  let commands = ["exit 0", "exit 0", "exit 0", "exit 0", "exit 0", "exit 0"]
  match run_parallel_commands(commands, worker_count=3) {
    Ok(_) => ()
    Err(error) => abort("native worker pool failed: " + error)
  }
}
