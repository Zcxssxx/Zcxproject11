pub(all) struct LocalExecutor {}

fn join_strings(arr : Array[String], separator : String) -> String {
  let mut res = ""
  for i, val in arr {
    if i > 0 {
      res += separator
    }
    res += val
  }
  res
}

pub impl Executor for LocalExecutor with run(self : LocalExecutor, edge : BuildEdge, rules : Map[String, Rule]) -> Result[Unit, String] {
  let _ = self
  let rule_opt : Rule? = rules.get(edge.rule)
  match rule_opt {
    Some(rule) => {
      let raw_cmd = rule.command
      let in_str = join_strings(edge.inputs, " ")
      let out_str = join_strings(edge.outputs, " ")
      let cmd = replace_string(replace_string(raw_cmd, "$in", in_str), "$out", out_str)
      println("Executing: " + cmd)
      let exit_code = execute_command(cmd)
      if exit_code == 0 {
        Ok(())
      } else {
        Err("Command failed with exit code: " + exit_code.to_string())
      }
    }
    None => Err("Unknown rule: " + edge.rule)
  }
}

fn replace_string(s : String, pattern : String, replacement : String) -> String {
  let mut result = ""
  let mut i = 0
  let pattern_len = pattern.length()
  while i < s.length() {
    if i + pattern_len <= s.length() && s[i : i + pattern_len].to_owned() == pattern {
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
