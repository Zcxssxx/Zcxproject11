///|
pub(all) enum ValidationSeverity {
  Error
  Warning
} derive(Debug, Eq)

///|
pub(all) struct ValidationIssue {
  code : String
  message : String
  subject : String
  severity : ValidationSeverity
} derive(Debug, Eq)

///|
pub fn ValidationIssue::to_text(self : ValidationIssue) -> String {
  let level = match self.severity {
    Error => "error"
    Warning => "warning"
  }
  level + "[" + self.code + "] " + self.message + ": " + self.subject
}

///|
fn validation_issue(
  code : String,
  message : String,
  subject : String,
  severity : ValidationSeverity,
) -> ValidationIssue {
  { code, message, subject, severity }
}

///|
/// Check the supported Ninja subset before graph planning or execution.
///
/// Errors indicate an invalid build graph. Warnings describe valid but
/// unusual edges, such as a source-generating rule with no inputs.
pub fn Manifest::validation_issues(self : Manifest) -> Array[ValidationIssue] {
  let issues : Array[ValidationIssue] = []
  if self.rules.is_empty() && self.builds.is_empty() {
    issues.push(
      validation_issue(
        "empty-manifest",
        "manifest has no rules or build edges",
        "manifest",
        Error,
      ),
    )
    return issues
  }

  if self.rules.is_empty() {
    issues.push(
      validation_issue("empty-rules", "manifest has no rules", "rules", Error),
    )
  }
  if self.builds.is_empty() {
    issues.push(
      validation_issue(
        "empty-builds",
        "manifest has no build edges",
        "builds",
        Warning,
      ),
    )
  }

  let outputs : Map[String, Int] = Map([])
  for edge in self.builds {
    if edge.outputs.is_empty() {
      issues.push(
        validation_issue(
          "empty-outputs",
          "build edge must produce at least one output",
          edge.key(),
          Error,
        ),
      )
    }
    if !self.rules.contains(edge.rule) {
      issues.push(
        validation_issue(
          "unknown-rule",
          "build edge references a rule that is not declared",
          edge.rule,
          Error,
        ),
      )
    }
    if edge.inputs.is_empty() {
      issues.push(
        validation_issue(
          "source-generator",
          "build edge has no inputs and is treated as a source generator",
          edge.key(),
          Warning,
        ),
      )
    }
    for output in edge.outputs {
      let count = match outputs.get(output) {
        Some(value) => value + 1
        None => 1
      }
      outputs[output] = count
    }
  }

  for output, count in outputs {
    if count > 1 {
      issues.push(
        validation_issue(
          "duplicate-output",
          "multiple build edges produce the same output",
          output,
          Error,
        ),
      )
    }
  }
  issues
}

///|
pub fn Manifest::is_valid(self : Manifest) -> Bool {
  for issue in self.validation_issues() {
    if issue.severity == Error {
      return false
    }
  }
  true
}

///|
pub fn Manifest::validate(self : Manifest) -> Result[Unit, String] {
  let issues = self.validation_issues()
  let errors : Array[String] = []
  for issue in issues {
    if issue.severity == Error {
      errors.push(issue.to_text())
    }
  }
  if errors.is_empty() {
    Ok(())
  } else {
    Err(join_strings(errors, "\n"))
  }
}
