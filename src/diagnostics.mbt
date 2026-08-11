///|
pub(all) enum DiagnosticKind {
  Parse
  Validation
  Graph
  Execution
} derive(Debug, Eq)

///|
pub impl Show for DiagnosticKind with fn output(
  self : DiagnosticKind,
  logger : &Logger,
) -> Unit {
  match self {
    Parse => logger.write_string("Parse")
    Validation => logger.write_string("Validation")
    Graph => logger.write_string("Graph")
    Execution => logger.write_string("Execution")
  }
}

///|
pub(all) struct Diagnostic {
  kind : DiagnosticKind
  code : String
  message : String
  subject : String
  hint : String
} derive(Debug, Eq)

///|
pub fn Diagnostic::to_text(self : Diagnostic) -> String {
  let kind = match self.kind {
    Parse => "parse"
    Validation => "validation"
    Graph => "graph"
    Execution => "execution"
  }
  kind +
  "[" +
  self.code +
  "] " +
  self.message +
  " (" +
  self.subject +
  ") hint: " +
  self.hint
}

///|
fn diagnostic(
  kind : DiagnosticKind,
  code : String,
  message : String,
  subject : String,
  hint : String,
) -> Diagnostic {
  { kind, code, message, subject, hint }
}

///|
pub fn Manifest::diagnostics_for_manifest(self : Manifest) -> Array[Diagnostic] {
  let result : Array[Diagnostic] = []
  for issue in self.validation_issues() {
    let hint = match issue.code {
      "unknown-rule" => "declare the rule before using it"
      "empty-outputs" => "add at least one output to the build edge"
      "duplicate-output" => "make one edge the unique producer"
      "empty-manifest" => "add a rule and a build edge"
      "empty-rules" => "declare at least one rule"
      _ => "review the supported manifest subset"
    }
    result.push(
      diagnostic(Validation, issue.code, issue.message, issue.subject, hint),
    )
  }
  result
}

///|
pub fn diagnostics_for_parse(error : ParseError) -> Diagnostic {
  match error {
    ParseError::SyntaxError(message, line~, col~) =>
      diagnostic(
        Parse,
        "syntax-error",
        message,
        line.to_string() + ":" + col.to_string(),
        "check the rule, command, colon, and build input syntax",
      )
    ParseError::UnexpectedToken(token, expected~) =>
      diagnostic(
        Parse,
        "unexpected-token",
        "unexpected " + token.to_string(),
        expected,
        "use a supported rule or build declaration",
      )
  }
}

///|
pub fn diagnostics_for_graph(error : String) -> Diagnostic {
  diagnostic(
    Graph,
    if error.contains("SCC") {
      "cycle"
    } else {
      "graph-error"
    },
    error,
    "dependency graph",
    "inspect the target's producer and input edges",
  )
}

///|
pub fn diagnostics_text(diagnostics : Array[Diagnostic]) -> String {
  let lines : Array[String] = []
  for item in diagnostics {
    lines.push(item.to_text())
  }
  join_strings(lines, "\n")
}
