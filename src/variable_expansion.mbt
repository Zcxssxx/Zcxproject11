///|
/// Values available while rendering one build edge.
///
/// The context is deliberately explicit: portable planning never reads the
/// process environment, so WASM-GC, JS, and native hosts render the same
/// command from the same inputs.
pub(all) struct ExpansionContext {
  inputs : Array[String]
  outputs : Array[String]
  variables : Map[String, String]
} derive(Debug, Eq)

///|
pub fn ExpansionContext::new(
  inputs~ : Array[String],
  outputs~ : Array[String],
  variables~ : Map[String, String],
) -> ExpansionContext {
  { inputs, outputs, variables }
}

///|
fn expansion_value(
  name : String,
  context : ExpansionContext,
  resolving : Map[String, Bool],
  depth : Int,
) -> Result[String, String] {
  if depth > 32 {
    return Err("variable expansion exceeded the maximum depth of 32")
  }
  if name == "in" {
    return Ok(join_strings(context.inputs, " "))
  }
  if name == "out" {
    return Ok(join_strings(context.outputs, " "))
  }
  if name == "in_newline" {
    return Ok(join_strings(context.inputs, "\n"))
  }
  match context.variables.get(name) {
    None => Ok("")
    Some(value) => {
      if resolving.contains(name) {
        return Err("recursive variable expansion detected for $" + name)
      }
      resolving[name] = true
      let result = expand_template(value, context, resolving, depth + 1)
      resolving.remove(name)
      result
    }
  }
}

///|
fn variable_name_end(text : String, start : Int) -> Int {
  let mut cursor = start
  while cursor < text.length() {
    let ch = get_char_at(text, cursor)
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' ||
      ch == '.' {
      cursor += 1
    } else {
      break
    }
  }
  cursor
}

///|
fn closing_brace(text : String, start : Int) -> Int? {
  let mut cursor = start
  while cursor < text.length() {
    if get_char_at(text, cursor) == '}' {
      return Some(cursor)
    }
    cursor += 1
  }
  None
}

///|
fn expand_template(
  text : String,
  context : ExpansionContext,
  resolving : Map[String, Bool],
  depth : Int,
) -> Result[String, String] {
  let mut result = ""
  let mut cursor = 0
  while cursor < text.length() {
    let ch = get_char_at(text, cursor)
    if ch != '$' {
      result += "\{ch}"
      cursor += 1
      continue
    }
    if cursor + 1 >= text.length() {
      result += "$"
      cursor += 1
      continue
    }
    let next = get_char_at(text, cursor + 1)
    if next == '$' {
      result += "$"
      cursor += 2
      continue
    }
    if next == '{' {
      let end = closing_brace(text, cursor + 2)
      match end {
        None => return Err("unterminated variable reference")
        Some(close) => {
          let name = text[cursor + 2:close].to_owned()
          match expansion_value(name, context, resolving, depth) {
            Ok(value) => result += value
            Err(error) => return Err(error)
          }
          cursor = close + 1
          continue
        }
      }
    }
    let end = variable_name_end(text, cursor + 1)
    if end == cursor + 1 {
      result += "$"
      cursor += 1
      continue
    }
    let name = text[cursor + 1:end].to_owned()
    match expansion_value(name, context, resolving, depth) {
      Ok(value) => result += value
      Err(error) => return Err(error)
    }
    cursor = end
  }
  Ok(result)
}

///|
/// Expand command placeholders. Missing named variables intentionally become
/// empty strings, matching the permissive behavior of common build tools.
pub fn expand_command_checked(
  text : String,
  context : ExpansionContext,
) -> Result[String, String] {
  expand_template(text, context, Map([]), 0)
}

///|
/// Expand a command and return an empty string for invalid recursive input.
/// Call `expand_command_checked` when the caller needs the diagnostic.
pub fn expand_command(text : String, context : ExpansionContext) -> String {
  match expand_command_checked(text, context) {
    Ok(value) => value
    Err(_) => ""
  }
}

///|
pub fn BuildEdge::render_command_with_variables(
  self : BuildEdge,
  rules : Map[String, Rule],
  variables : Map[String, String],
) -> Result[String, String] {
  match rules.get(self.rule) {
    None => Err("Unknown rule: " + self.rule)
    Some(rule) =>
      expand_command_checked(
        rule.command,
        ExpansionContext::new(
          inputs=self.inputs,
          outputs=self.outputs,
          variables~,
        ),
      )
  }
}
