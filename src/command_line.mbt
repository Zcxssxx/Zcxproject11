///|
/// A structured command line that can be rendered for a shell or response
/// file without losing argument boundaries.
pub(all) struct CommandLine {
  executable : String
  arguments : Array[String]
} derive(Debug, Eq)

///|
pub fn CommandLine::new(
  executable~ : String,
  arguments~ : Array[String],
) -> CommandLine {
  { executable, arguments }
}

///|
fn quote_argument(argument : String) -> String {
  if argument == "" {
    return "\"\""
  }
  let mut safe = true
  for ch in argument {
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '"' || ch == '\\' {
      safe = false
    }
  }
  if safe {
    argument
  } else {
    let mut quoted = "\""
    for ch in argument {
      if ch == '"' || ch == '\\' {
        quoted += "\\"
      }
      quoted += "\{ch}"
    }
    quoted + "\""
  }
}

///|
pub fn CommandLine::to_shell_text(self : CommandLine) -> String {
  let rendered : Array[String] = [quote_argument(self.executable)]
  for argument in self.arguments {
    rendered.push(quote_argument(argument))
  }
  join_strings(rendered, " ")
}

///|
pub fn CommandLine::to_response_file(self : CommandLine) -> String {
  let rendered : Array[String] = []
  for argument in self.arguments {
    rendered.push(quote_argument(argument))
  }
  join_strings(rendered, " ") + "\n"
}

///|
pub fn CommandLine::append(
  self : CommandLine,
  argument : String,
) -> CommandLine {
  let arguments = self.arguments.copy()
  arguments.push(argument)
  { ..self, arguments, }
}

///|
pub fn CommandLine::has_unsafe_argument(self : CommandLine) -> Bool {
  for argument in self.arguments {
    for ch in argument {
      if ch == ' ' || ch == '\t' || ch == '\n' || ch == '"' || ch == '\\' {
        return true
      }
    }
  }
  false
}

///|
/// Build a structured command from a response-file-compatible token stream.
pub fn command_line_from_text(text : String) -> Result[CommandLine, String] {
  match parse_response_file(text) {
    Err(error) => Err(error)
    Ok(tokens) => {
      if tokens.is_empty() {
        return Err("command line is empty")
      }
      let arguments : Array[String] = []
      for index, token in tokens {
        if index > 0 {
          arguments.push(token)
        }
      }
      Ok({ executable: tokens[0], arguments })
    }
  }
}
