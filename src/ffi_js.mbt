///|
/// JavaScript host ABI equivalent of the WASM command runner.
extern "js" fn execute_command_host(cmd : String) -> Int = "MoonNinjaHost" "execute_command"

///|
pub fn execute_command(cmd : String) -> Int {
  execute_command_host(cmd)
}
