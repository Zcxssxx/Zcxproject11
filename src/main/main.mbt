///|
fn main {
  let ninja_input =
    #|rule cc
    #|  command = echo Compile $in -o $out
    #|rule link
    #|  command = echo Link $in -o $out
    #|build util.o: cc util.c
    #|build main.o: cc main.c
    #|build app: link main.o util.o
    #|

  let parser = @src.Parser::new(ninja_input)
  try {
    let manifest = parser.parse()
    println("Manifest parsed successfully.")
    println("Rule count: " + manifest.rules.length().to_string())
    println("Build edge count: " + manifest.builds.length().to_string())
    let graph = @src.DepGraph::build(manifest)
    let executor = @src.LocalExecutor::{  }
    let scheduler = @src.Scheduler::{ graph, executor }
    let snapshot : Map[String, Int] = {
      "main.c": 10,
      "util.c": 10,
      "main.o": 9,
      "util.o": 11,
      "app": 8,
    }
    match scheduler.run_incremental("app", snapshot) {
      Ok(commands) => {
        println("Incremental build successful.")
        println("Executed commands: " + commands.length().to_string())
      }
      Err(e) => println("Build failed: " + e)
    }
  } catch {
    @src.ParseError::SyntaxError(msg, line~, col~) =>
      println(
        "Syntax error: " +
        msg +
        " at " +
        line.to_string() +
        ":" +
        col.to_string(),
      )
    @src.ParseError::UnexpectedToken(tok, expected~) =>
      println("Unexpected token: \{tok}, expected: \{expected}")
  }
}
