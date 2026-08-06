///|
#borrow(path)
extern "c" fn file_mtime_seconds(path : Bytes) -> Int64 = "moon_ninja_file_mtime_seconds"

///|
#borrow(path)
extern "c" fn file_mtime_nanos(path : Bytes) -> Int = "moon_ninja_file_mtime_nanos"

///|
#borrow(path)
extern "c" fn file_size(path : Bytes) -> Int = "moon_ninja_file_size"

///|
#borrow(path)
extern "c" fn file_hash(path : Bytes) -> UInt64 = "moon_ninja_file_hash"

///|
/// Read a real native filesystem fingerprint using `stat` and a streaming
/// content hash. A negative size means that the file could not be read.
pub fn snapshot_file(path : String) -> @core.FileFingerprint {
  let path_bytes = @utf8.encode((path + "\u0000")[:])
  @core.FileFingerprint::from_metadata(
    mtime_seconds=file_mtime_seconds(path_bytes),
    mtime_nanos=file_mtime_nanos(path_bytes),
    size=file_size(path_bytes),
    content_hash=file_hash(path_bytes).to_string(),
  )
}
