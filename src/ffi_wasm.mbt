///|
/// The host must provide `moon_ninja.execute_command` when instantiating the
/// WASM-GC module. There is intentionally no print-and-return mock.
extern "wasm" fn execute_command_host(cmd : String) -> Int = "moon_ninja" "execute_command"

///|
pub fn execute_command(cmd : String) -> Int {
  execute_command_host(cmd)
}
