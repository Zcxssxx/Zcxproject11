///|
pub(all) struct Rule {
  name : String
  command : String
}

///|
pub(all) struct BuildEdge {
  rule : String
  inputs : Array[String]
  outputs : Array[String]
}

///|
pub(all) struct Manifest {
  rules : Map[String, Rule]
  builds : Array[BuildEdge]
}

///|
pub fn BuildEdge::key(self : BuildEdge) -> String {
  let mut key = self.rule + "::"
  for i, output in self.outputs {
    if i > 0 {
      key += ","
    }
    key += output
  }
  key
}

///|
pub fn BuildEdge::render_command(
  self : BuildEdge,
  rules : Map[String, Rule],
) -> Result[String, String] {
  match rules.get(self.rule) {
    Some(rule) => {
      let raw_cmd = rule.command
      let in_str = join_strings(self.inputs, " ")
      let out_str = join_strings(self.outputs, " ")
      Ok(
        replace_string(replace_string(raw_cmd, "$in", in_str), "$out", out_str),
      )
    }
    None => Err("Unknown rule: " + self.rule)
  }
}

///|
fn join_strings(arr : Array[String], separator : String) -> String {
  let mut result = ""
  for i, value in arr {
    if i > 0 {
      result += separator
    }
    result += value
  }
  result
}

///|
fn replace_string(s : String, pattern : String, replacement : String) -> String {
  let mut result = ""
  let mut i = 0
  let pattern_len = pattern.length()
  while i < s.length() {
    if i + pattern_len <= s.length() &&
      s[i:i + pattern_len].to_owned() == pattern {
      result += replacement
      i += pattern_len
    } else {
      let ch = get_char_at(s, i)
      result += "\{ch}"
      i += 1
    }
  }
  result
}
