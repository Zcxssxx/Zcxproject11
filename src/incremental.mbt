///|
pub(all) enum BuildDecision {
  UpToDate
  NeedsBuild(String)
} derive(Debug, Eq)

///|
pub fn BuildEdge::evaluate_incremental(
  self : BuildEdge,
  snapshot : Map[String, Int],
) -> BuildDecision {
  if self.outputs.is_empty() {
    return NeedsBuild("edge has no outputs")
  }
  let mut newest_input = 0
  let mut has_input = false
  for input in self.inputs {
    match snapshot.get(input) {
      Some(stamp) =>
        if !has_input || stamp > newest_input {
          newest_input = stamp
          has_input = true
        }
      None => return NeedsBuild("missing input: " + input)
    }
  }

  let mut oldest_output = 0
  let mut has_output = false
  for output in self.outputs {
    match snapshot.get(output) {
      Some(stamp) =>
        if !has_output || stamp < oldest_output {
          oldest_output = stamp
          has_output = true
        }
      None => return NeedsBuild("missing output: " + output)
    }
  }

  if !has_input {
    return UpToDate
  }
  if newest_input > oldest_output {
    return NeedsBuild("outputs are older than at least one input")
  }
  UpToDate
}

///|
pub fn BuildEdge::refresh_outputs(
  self : BuildEdge,
  snapshot : Map[String, Int],
  tick : Int,
) -> Int {
  let mut next_tick = tick
  for input in self.inputs {
    match snapshot.get(input) {
      Some(stamp) => if stamp >= next_tick { next_tick = stamp + 1 }
      None => ()
    }
  }
  for output in self.outputs {
    snapshot[output] = next_tick
  }
  next_tick + 1
}
