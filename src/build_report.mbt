///|
/// Build execution outcome used by frontends, CI summaries, and telemetry.
pub(all) enum BuildReportStatus {
  Pending
  Succeeded
  Failed
} derive(Debug, Eq)

///|
/// A compact, deterministic summary of one materialized build.
pub(all) struct BuildReport {
  status : BuildReportStatus
  target : String
  waves : Int
  commands : Int
  cache_hits : Int
  cache_misses : Int
  failures : Array[String]
  outputs : Array[String]
} derive(Debug, Eq)

///|
/// Start an empty report for a target.
pub fn build_report(target : String) -> BuildReport {
  {
    status: Pending,
    target,
    waves: 0,
    commands: 0,
    cache_hits: 0,
    cache_misses: 0,
    failures: [],
    outputs: [],
  }
}

///|
/// Record a scheduled wave without changing the report's target.
pub fn BuildReport::record_wave(
  self : BuildReport,
  command_count : Int,
) -> BuildReport {
  { ..self, waves: self.waves + 1, commands: self.commands + command_count }
}

///|
/// Record one cache hit and its materialized output.
pub fn BuildReport::record_cache_hit(
  self : BuildReport,
  output : String,
) -> BuildReport {
  let outputs = self.outputs.copy()
  if !outputs.contains(output) {
    outputs.push(output)
  }
  { ..self, cache_hits: self.cache_hits + 1, outputs }
}

///|
/// Record one cache miss and its materialized output.
pub fn BuildReport::record_cache_miss(
  self : BuildReport,
  output : String,
) -> BuildReport {
  let outputs = self.outputs.copy()
  if !outputs.contains(output) {
    outputs.push(output)
  }
  { ..self, cache_misses: self.cache_misses + 1, outputs }
}

///|
/// Record a failure and retain its first-seen order.
pub fn BuildReport::record_failure(
  self : BuildReport,
  message : String,
) -> BuildReport {
  let failures = self.failures.copy()
  failures.push(message)
  { ..self, status: Failed, failures }
}

///|
/// Mark a report successful only when no failure was recorded.
pub fn BuildReport::finish(self : BuildReport) -> BuildReport {
  if self.failures.is_empty() {
    { ..self, status: Succeeded }
  } else {
    self
  }
}

///|
/// Whether this report can be used as a successful incremental state.
pub fn BuildReport::is_success(self : BuildReport) -> Bool {
  self.status == Succeeded && self.failures.is_empty()
}

///|
/// Number of commands that actually missed the cache.
pub fn BuildReport::executed_commands(self : BuildReport) -> Int {
  self.cache_misses
}

///|
/// Number of cache observations recorded for this report.
pub fn BuildReport::cache_observations(self : BuildReport) -> Int {
  self.cache_hits + self.cache_misses
}

///|
/// Integer cache hit percentage, stable for empty reports.
pub fn BuildReport::cache_hit_percent(self : BuildReport) -> Int {
  let total = self.cache_observations()
  if total == 0 {
    100
  } else {
    self.cache_hits * 100 / total
  }
}

///|
/// Return a report with all counters and collections combined.
pub fn BuildReport::merge(
  self : BuildReport,
  other : BuildReport,
) -> BuildReport {
  let failures = self.failures.copy()
  for failure in other.failures {
    failures.push(failure)
  }
  let outputs = self.outputs.copy()
  for output in other.outputs {
    if !outputs.contains(output) {
      outputs.push(output)
    }
  }
  let status = if !failures.is_empty() {
    Failed
  } else if self.status == Succeeded && other.status == Succeeded {
    Succeeded
  } else {
    Pending
  }
  {
    status,
    target: self.target,
    waves: self.waves + other.waves,
    commands: self.commands + other.commands,
    cache_hits: self.cache_hits + other.cache_hits,
    cache_misses: self.cache_misses + other.cache_misses,
    failures,
    outputs,
  }
}

///|
fn report_status_text(status : BuildReportStatus) -> String {
  match status {
    Pending => "pending"
    Succeeded => "succeeded"
    Failed => "failed"
  }
}

///|
/// Render a machine-readable, line-oriented summary for CI logs.
pub fn BuildReport::to_text(self : BuildReport) -> String {
  let lines : Array[String] = []
  lines.push("status=" + report_status_text(self.status))
  lines.push("target=" + self.target)
  lines.push("waves=" + self.waves.to_string())
  lines.push("commands=" + self.commands.to_string())
  lines.push("executed=" + self.executed_commands().to_string())
  lines.push("cache_hits=" + self.cache_hits.to_string())
  lines.push("cache_misses=" + self.cache_misses.to_string())
  lines.push("cache_hit_percent=" + self.cache_hit_percent().to_string())
  lines.push("outputs=" + self.outputs.length().to_string())
  lines.push("failures=" + self.failures.length().to_string())
  for failure in self.failures {
    lines.push("failure=" + failure)
  }
  lines.join("\n")
}

///|
/// Validate invariants before persisting a report as build state.
pub fn BuildReport::validate(self : BuildReport) -> Result[Unit, String] {
  if self.waves < 0 {
    Err("wave count cannot be negative")
  } else if self.commands < 0 {
    Err("command count cannot be negative")
  } else if self.cache_hits < 0 || self.cache_misses < 0 {
    Err("cache counters cannot be negative")
  } else if self.cache_observations() > self.commands {
    Err("cache observations exceed scheduled commands")
  } else if self.status == Succeeded && !self.failures.is_empty() {
    Err("successful report cannot contain failures")
  } else {
    Ok(())
  }
}

///|
/// Whether the report has reached a terminal state.
pub fn BuildReport::is_terminal(self : BuildReport) -> Bool {
  self.status == Succeeded || self.status == Failed
}

///|
/// Whether at least one reusable artifact was observed.
pub fn BuildReport::has_cache_reuse(self : BuildReport) -> Bool {
  self.cache_hits > 0
}

///|
/// Return a stable one-line failure summary for dashboards.
pub fn BuildReport::failure_summary(self : BuildReport) -> String {
  if self.failures.is_empty() {
    "none"
  } else {
    self.failures.join(" | ")
  }
}

///|
/// Check whether an output was recorded by this build.
pub fn BuildReport::contains_output(
  self : BuildReport,
  output : String,
) -> Bool {
  self.outputs.contains(output)
}
