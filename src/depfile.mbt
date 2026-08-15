///|
/// A parsed Make-style dependency file produced by compilers such as GCC.
pub(all) struct Depfile {
  target : String
  dependencies : Array[String]
} derive(Debug, Eq)

///|
fn depfile_unescape(text : String) -> String {
  let mut result = ""
  let mut escaped = false
  for ch in text {
    if escaped {
      result += "\{ch}"
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else {
      result += "\{ch}"
    }
  }
  if escaped {
    result += "\\"
  }
  result
}

///|
fn depfile_join_continuations(text : String) -> String {
  let mut result = ""
  let mut cursor = 0
  while cursor < text.length() {
    let ch = get_char_at(text, cursor)
    if ch == '\\' && cursor + 1 < text.length() {
      let next = get_char_at(text, cursor + 1)
      if next == '\n' {
        result += " "
        cursor += 2
        continue
      }
      if next == '\r' &&
        cursor + 2 < text.length() &&
        get_char_at(text, cursor + 2) == '\n' {
        result += " "
        cursor += 3
        continue
      }
    }
    result += "\{ch}"
    cursor += 1
  }
  result
}

///|
fn depfile_separator(text : String) -> Int? {
  let mut cursor = 0
  let mut escaped = false
  while cursor < text.length() {
    let ch = get_char_at(text, cursor)
    if escaped {
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else if ch == ':' {
      return Some(cursor)
    }
    cursor += 1
  }
  None
}

///|
fn depfile_words(text : String) -> Array[String] {
  let words : Array[String] = []
  let mut current = ""
  let mut escaped = false
  for ch in text {
    if escaped {
      current += "\{ch}"
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      if current != "" {
        words.push(current)
        current = ""
      }
    } else {
      current += "\{ch}"
    }
  }
  if escaped {
    current += "\\"
  }
  if current != "" {
    words.push(current)
  }
  words
}

///|
/// Parse one or more Make-style depfile rules. Multiple target rules are
/// rejected so callers cannot silently apply the wrong dependency set.
pub fn parse_depfile(text : String) -> Result[Depfile, String] {
  let flattened = depfile_join_continuations(text)
  let separator = match depfile_separator(flattened) {
    Some(value) => value
    None => return Err("depfile is missing ':' separator")
  }
  let raw_target = flattened[:separator].to_owned().trim().to_owned()
  if raw_target == "" {
    return Err("depfile target is empty")
  }
  let targets = depfile_words(raw_target)
  if targets.length() != 1 {
    return Err("depfile must contain exactly one target")
  }
  let raw_dependencies = flattened[separator + 1:].to_owned()
  let dependencies : Array[String] = []
  for word in depfile_words(raw_dependencies) {
    let dependency = depfile_unescape(word).trim().to_owned()
    if dependency != "" && !dependencies.contains(dependency) {
      dependencies.push(dependency)
    }
  }
  Ok({ target: depfile_unescape(targets[0]), dependencies })
}

///|
/// Merge a depfile into the build edge that produces its target.
pub fn Manifest::apply_depfile(
  self : Manifest,
  depfile : Depfile,
) -> Result[Manifest, String] {
  let mut found = false
  let updated_builds : Array[BuildEdge] = []
  for edge in self.builds {
    if edge.outputs.contains(depfile.target) {
      found = true
      let inputs = edge.inputs.copy()
      for dependency in depfile.dependencies {
        if !inputs.contains(dependency) {
          inputs.push(dependency)
        }
      }
      updated_builds.push({ ..edge, inputs, })
    } else {
      updated_builds.push(edge)
    }
  }
  if !found {
    Err("depfile target is not produced by the manifest: " + depfile.target)
  } else {
    Ok({ ..self, builds: updated_builds })
  }
}
