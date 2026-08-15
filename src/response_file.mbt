///|
/// Parse the small, portable response-file language used by compiler drivers.
/// It supports whitespace, single/double quotes, backslash escapes, and lines
/// beginning with `#` comments. Shell expansion is intentionally out of scope.
pub fn parse_response_file(text : String) -> Result[Array[String], String] {
  let arguments : Array[String] = []
  let mut current = ""
  let mut escaped = false
  let mut quote : Char? = None
  let mut at_token_start = true
  let mut in_comment = false

  fn flush() -> Unit {
    if current != "" {
      arguments.push(current)
      current = ""
    }
    at_token_start = true
  }

  for ch in text {
    if in_comment {
      if ch == '\n' {
        in_comment = false
        at_token_start = true
      } else {
        continue
      }
    }
    match quote {
      Some(mark) => {
        if escaped {
          current += "\{ch}"
          escaped = false
        } else if ch == '\\' {
          escaped = true
        } else if ch == mark {
          quote = None
        } else {
          current += "\{ch}"
        }
        at_token_start = false
      }
      None =>
        if escaped {
          current += "\{ch}"
          escaped = false
          at_token_start = false
        } else if ch == '\\' {
          escaped = true
          at_token_start = false
        } else if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
          flush()
        } else if ch == '#' && at_token_start {
          current = ""
          at_token_start = true
          in_comment = true
        } else if ch == '"' || ch == '\'' {
          quote = Some(ch)
          at_token_start = false
        } else {
          current += "\{ch}"
          at_token_start = false
        }
    }
  }
  if escaped {
    return Err("response file ends with an escape")
  }
  match quote {
    Some(_) => Err("response file has an unterminated quote")
    None => {
      flush()
      Ok(arguments)
    }
  }
}

///|
fn response_file_token(text : String) -> String {
  text[1:].to_owned()
}

///|
fn materialize_response_tokens(
  tokens : Array[String],
  files : Map[String, String],
  depth : Int,
) -> Result[Array[String], String] {
  if depth > 8 {
    return Err("response file nesting exceeded the maximum depth of 8")
  }
  let result : Array[String] = []
  for token in tokens {
    if token.length() > 1 && token[0] == '@' {
      let path = response_file_token(token)
      match files.get(path) {
        None => return Err("response file is missing: " + path)
        Some(contents) =>
          match parse_response_file(contents) {
            Err(error) => return Err(path + ": " + error)
            Ok(nested) =>
              match materialize_response_tokens(nested, files, depth + 1) {
                Err(error) => return Err(error)
                Ok(expanded) =>
                  for item in expanded {
                    result.push(item)
                  }
              }
          }
      }
    } else {
      result.push(token)
    }
  }
  Ok(result)
}

///|
/// Expand `@file` references from an in-memory response-file table. Keeping
/// file contents at the boundary makes this API usable on WASM-GC and JS.
pub fn materialize_response_command(
  command : String,
  files : Map[String, String],
) -> Result[Array[String], String] {
  match parse_response_file(command) {
    Err(error) => Err(error)
    Ok(tokens) => materialize_response_tokens(tokens, files, 0)
  }
}
