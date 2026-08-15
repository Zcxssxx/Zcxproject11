///|
/// A structured command-line validation finding suitable for diagnostics.
/// Hosts can display these findings before execution and attach the argument
/// index to a UI or CI annotation without parsing human-readable text.
/// This keeps process launch policy separate from command rendering and makes
/// the same validation available to native and browser-hosted plans.
pub(all) struct CommandIssue {
  argument_index : Int
  code : String
  message : String
} derive(Debug, Eq)

///|
pub fn CommandIssue::to_text(self : CommandIssue) -> String {
  "argument[" +
  self.argument_index.to_string() +
  "] " +
  self.code +
  ": " +
  self.message
}

///|
fn command_has_whitespace(text : String) -> Bool {
  for ch in text {
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' {
      return true
    }
  }
  false
}

///|
/// Validate command structure before a host invokes a process.
pub fn CommandLine::validate(self : CommandLine) -> Array[CommandIssue] {
  let issues : Array[CommandIssue] = []
  if self.executable == "" {
    issues.push({
      argument_index: 0,
      code: "empty-executable",
      message: "command has no executable",
    })
  } else if command_has_whitespace(self.executable) {
    issues.push({
      argument_index: 0,
      code: "split-executable",
      message: "executable must be one argument; quote it before parsing",
    })
  }
  for index, argument in self.arguments {
    if argument == "" {
      issues.push({
        argument_index: index + 1,
        code: "empty-argument",
        message: "empty arguments must be intentional and quoted",
      })
    }
    if argument.contains("\n") || argument.contains("\r") {
      issues.push({
        argument_index: index + 1,
        code: "newline-argument",
        message: "newline in a process argument is not portable",
      })
    }
  }
  issues
}

///|
pub fn CommandLine::is_valid(self : CommandLine) -> Bool {
  self.validate().is_empty()
}
