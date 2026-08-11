///|
pub fn Rule::to_ninja(self : Rule) -> String {
  "rule " + self.name + "\n  command = " + self.command + "\n"
}

///|
pub fn BuildEdge::to_ninja(self : BuildEdge) -> String {
  let suffix = if self.inputs.is_empty() {
    ""
  } else {
    " " + join_strings(self.inputs, " ")
  }
  "build " + join_strings(self.outputs, " ") + ": " + self.rule + suffix + "\n"
}

///|
/// Serialize the supported subset into a deterministic, reviewable manifest.
pub fn Manifest::to_ninja(self : Manifest) -> String {
  let mut result = "# MoonNinja generated manifest\n"
  for _, rule in self.rules {
    result += "\n" + rule.to_ninja()
  }
  for edge in self.builds {
    result += edge.to_ninja()
  }
  result
}
