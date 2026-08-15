///|
/// Normalize a build path without consulting the host filesystem.
/// Both slash styles are accepted so plans are reproducible across CI hosts.
pub fn normalize_build_path(path : String) -> Result[String, String] {
  if path == "" {
    return Err("build path is empty")
  }
  let normalized_separators = path.replace(old="\\", new="/")
  let absolute = normalized_separators[0] == '/' ||
    (normalized_separators.length() > 1 && normalized_separators[1] == ':')
  if absolute {
    return Err("absolute paths are not portable build inputs")
  }
  let segments : Array[String] = []
  let mut current = ""
  let mut escaped_workspace = false
  fn flush_segment() -> Unit {
    if current == "" || current == "." {
      current = ""
    } else if current == ".." {
      if segments.is_empty() {
        escaped_workspace = true
        current = ""
      } else {
        ignore(segments.pop())
        current = ""
      }
    } else {
      segments.push(current)
      current = ""
    }
  }
  for ch in normalized_separators {
    if ch == '/' {
      flush_segment()
    } else {
      current += "\{ch}"
    }
  }
  flush_segment()
  if escaped_workspace || current == ".." {
    return Err("build path escapes the workspace")
  }
  if segments.is_empty() {
    Err("build path resolves to the workspace root")
  } else {
    Ok(join_strings(segments, "/"))
  }
}

///|
pub fn join_build_path(parts : Array[String]) -> Result[String, String] {
  normalize_build_path(join_strings(parts, "/"))
}

///|
pub fn is_relative_build_path(path : String) -> Bool {
  match normalize_build_path(path) {
    Ok(_) => true
    Err(_) => false
  }
}

///|
pub fn build_path_extension(path : String) -> String {
  let normalized = path.replace(old="\\", new="/")
  let slash = match normalized.rev_find("/") {
    Some(index) => index + 1
    None => 0
  }
  let dot = match normalized.rev_find(".") {
    Some(index) => index
    None => -1
  }
  if dot < slash || dot < 0 {
    ""
  } else {
    normalized[dot:].to_owned()
  }
}

///|
pub fn build_path_stem(path : String) -> String {
  let normalized = path.replace(old="\\", new="/")
  let slash = match normalized.rev_find("/") {
    Some(index) => index + 1
    None => 0
  }
  let dot = match normalized.rev_find(".") {
    Some(index) => index
    None => normalized.length()
  }
  let end = if dot < slash { normalized.length() } else { dot }
  normalized[slash:end].to_owned()
}

///|
pub fn build_path_directory(path : String) -> String {
  let normalized = path.replace(old="\\", new="/")
  match normalized.rev_find("/") {
    Some(index) => normalized[:index].to_owned()
    None => ""
  }
}
