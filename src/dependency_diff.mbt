///|
/// A deterministic comparison between two dependency sets for one output.
pub(all) struct DependencyDiff {
  target : String
  added : Array[String]
  removed : Array[String]
  unchanged : Array[String]
} derive(Debug, Eq)

///|
pub fn DependencyDiff::to_text(self : DependencyDiff) -> String {
  "target=" +
  self.target +
  " added=" +
  self.added.length().to_string() +
  " removed=" +
  self.removed.length().to_string() +
  " unchanged=" +
  self.unchanged.length().to_string()
}

///|
fn dependency_unique(values : Array[String]) -> Array[String] {
  let result : Array[String] = []
  for value in values {
    if !result.contains(value) {
      result.push(value)
    }
  }
  result
}

///|
/// Compare old and new depfile inputs while preserving first-seen order.
pub fn compare_dependencies(
  target : String,
  previous : Array[String],
  current : Array[String],
) -> DependencyDiff {
  let old_values = dependency_unique(previous)
  let new_values = dependency_unique(current)
  let added : Array[String] = []
  let removed : Array[String] = []
  let unchanged : Array[String] = []
  for value in new_values {
    if old_values.contains(value) {
      unchanged.push(value)
    } else {
      added.push(value)
    }
  }
  for value in old_values {
    if !new_values.contains(value) {
      removed.push(value)
    }
  }
  { target, added, removed, unchanged }
}
