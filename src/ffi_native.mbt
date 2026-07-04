extern "c" fn system_ffi(cmd : Bytes) -> Int = "system"

pub fn execute_command(cmd : String) -> Int {
  let null_terminated = cmd + "\x00"
  let bytes = @utf8.encode(null_terminated[:])
  system_ffi(bytes)
}
