///|
test "native snapshot reads mtime and content hash" {
  let fingerprint = snapshot_file("README.md")
  assert_true(fingerprint.size > 0)
  assert_true(fingerprint.content_hash != "")
}
