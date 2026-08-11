///|
#borrow(cmd)
extern "c" fn system_ffi(cmd : Bytes) -> Int = "moon_ninja_execute_command"

///|
pub fn execute_command(cmd : String) -> Int {
  let null_terminated = cmd + "\u0000"
  let bytes = @utf8.encode(null_terminated[:])
  system_ffi(bytes)
}
