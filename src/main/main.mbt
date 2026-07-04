fn main {
  let ninja_input =
    #|rule cc
    #|  command = echo Compile $in to $out
    #|build main.o: cc main.c
    #|

  let parser = @src.Parser::new(ninja_input)
  try {
    let manifest = parser.parse()
    println("Manifest parsed successfully.")
    let graph = @src.DepGraph::build(manifest)
    let executor = @src.LocalExecutor::{}
    let scheduler = @src.Scheduler::{ graph, executor }
    match scheduler.run_all("main.o") {
      Ok(_) => println("Build successful!")
      Err(e) => println("Build failed: " + e)
    }
  } catch {
    @src.ParseError::SyntaxError(msg, line~, col~) => println("Syntax error: " + msg + " at " + line.to_string() + ":" + col.to_string())
    @src.ParseError::UnexpectedToken(tok, expected~) => println("Unexpected token: \{tok}, expected: \{expected}")
  }
}
