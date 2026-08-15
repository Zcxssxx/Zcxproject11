///|
/// A portable sidecar entry for one planned build edge.
pub(all) struct BuildStateEntry {
  edge_key : String
  command_hash : String
  outputs : Array[String]
} derive(Debug, Eq)

///|
/// A deterministic, text-serializable incremental state cache.
pub(all) struct BuildState {
  entries : Array[BuildStateEntry]
} derive(Debug, Eq)

///|
fn state_hash(text : String) -> String {
  let mut hash : UInt64 = 14695981039346656037
  for ch in text {
    hash = (hash ^ ch.to_int().to_uint64()) * 1099511628211
  }
  hash.to_string()
}

///|
pub fn BuildState::from_plan(plan : MaterializedPlan) -> BuildState {
  let entries : Array[BuildStateEntry] = []
  for index, edge in plan.edges {
    let command = match plan.commands.get(index) {
      Some(value) => value
      None => ""
    }
    entries.push({
      edge_key: edge.key(),
      command_hash: state_hash(command),
      outputs: edge.outputs.copy(),
    })
  }
  { entries, }
}

///|
fn state_escape(text : String) -> String {
  let mut result = ""
  for ch in text {
    if ch == '\t' || ch == '\n' || ch == '\\' {
      result += "\\"
    }
    result += "\{ch}"
  }
  result
}

///|
fn state_unescape(text : String) -> String {
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
fn state_split(text : String, separator : Char) -> Array[String] {
  let result : Array[String] = []
  let mut current = ""
  let mut escaped = false
  for ch in text {
    if escaped {
      current += "\\"
      current += "\{ch}"
      escaped = false
    } else if ch == '\\' {
      escaped = true
    } else if ch == separator {
      result.push(current)
      current = ""
    } else {
      current += "\{ch}"
    }
  }
  if escaped {
    current += "\\"
  }
  result.push(current)
  result
}

///|
pub fn BuildState::to_text(self : BuildState) -> String {
  let mut result = "# MoonNinja build state v1\n"
  for entry in self.entries {
    let output_text : Array[String] = []
    for output in entry.outputs {
      output_text.push(state_escape(output))
    }
    result += state_escape(entry.edge_key) +
      "\t" +
      entry.command_hash +
      "\t" +
      join_strings(output_text, ",") +
      "\n"
  }
  result
}

///|
fn state_lines(text : String) -> Array[String] {
  let lines : Array[String] = []
  let mut current = ""
  for ch in text {
    if ch == '\n' {
      lines.push(current)
      current = ""
    } else if ch != '\r' {
      current += "\{ch}"
    }
  }
  if current != "" {
    lines.push(current)
  }
  lines
}

///|
/// Parse the state format and reject malformed records instead of silently
/// treating a corrupt cache as up to date.
pub fn parse_build_state(text : String) -> Result[BuildState, String] {
  let entries : Array[BuildStateEntry] = []
  for line in state_lines(text) {
    if line == "" || line == "# MoonNinja build state v1" {
      continue
    }
    let fields = state_split(line, '\t')
    if fields.length() != 3 || fields[0] == "" || fields[1] == "" {
      return Err("malformed build state record")
    }
    let outputs : Array[String] = []
    if fields[2] != "" {
      for output in state_split(fields[2], ',') {
        let value = state_unescape(output)
        if value != "" && !outputs.contains(value) {
          outputs.push(value)
        }
      }
    }
    entries.push({
      edge_key: state_unescape(fields[0]),
      command_hash: fields[1],
      outputs,
    })
  }
  Ok({ entries, })
}

///|
/// Return true when an edge is absent or its command has changed.
pub fn BuildState::needs_rebuild(
  self : BuildState,
  edge_key : String,
  command : String,
) -> Bool {
  let expected = state_hash(command)
  for entry in self.entries {
    if entry.edge_key == edge_key {
      return entry.command_hash != expected
    }
  }
  true
}

///|
/// Find a state entry by edge key for hosts that also inspect output paths.
pub fn BuildState::find(
  self : BuildState,
  edge_key : String,
) -> BuildStateEntry? {
  for entry in self.entries {
    if entry.edge_key == edge_key {
      return Some(entry)
    }
  }
  None
}
