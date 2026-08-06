///|
/// A filesystem identity used by incremental planning.
///
/// The timestamp is retained for Ninja-style ordering checks, while the
/// content digest prevents a same-mtime edit from being treated as up to date.
pub(all) struct FileFingerprint {
  mtime_seconds : Int64
  mtime_nanos : Int
  size : Int
  content_hash : String
} derive(Eq, Debug)

///|
pub fn FileFingerprint::from_bytes(
  bytes : Bytes,
  mtime_seconds~ : Int64,
  mtime_nanos~ : Int,
) -> FileFingerprint {
  {
    mtime_seconds,
    mtime_nanos,
    size: bytes.length(),
    content_hash: hash_bytes(bytes),
  }
}

///|
pub fn FileFingerprint::from_metadata(
  mtime_seconds~ : Int64,
  mtime_nanos~ : Int,
  size~ : Int,
  content_hash~ : String,
) -> FileFingerprint {
  { mtime_seconds, mtime_nanos, size, content_hash }
}

///|
/// A 64-bit FNV-1a stream keeps the snapshot portable across all MoonBit
/// backends without depending on a host crypto library.
fn hash_bytes(bytes : Bytes) -> String {
  let mut hash : UInt64 = 14695981039346656037
  for byte in bytes {
    hash = (hash ^ byte.to_uint64()) * 1099511628211
  }
  hash.to_string()
}

///|
pub fn FileFingerprint::is_newer_than(
  self : FileFingerprint,
  other : FileFingerprint,
) -> Bool {
  if self.mtime_seconds != other.mtime_seconds {
    self.mtime_seconds > other.mtime_seconds
  } else {
    self.mtime_nanos > other.mtime_nanos
  }
}
