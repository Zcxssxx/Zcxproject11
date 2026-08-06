///|
/// An executor for planning and deterministic tests.
///
/// It validates that the referenced rule exists and renders the command, but
/// does not invoke a host process. This is the portable executor used by the
/// default demo and by backend-independent scheduler tests.
pub(all) struct DryRunExecutor {}

///|
pub impl Executor for DryRunExecutor with fn run(
  self : DryRunExecutor,
  edge : BuildEdge,
  rules : Map[String, Rule],
) -> Result[Unit, String] {
  let _ = self
  match edge.render_command(rules) {
    Ok(_) => Ok(())
    Err(error) => Err(error)
  }
}
