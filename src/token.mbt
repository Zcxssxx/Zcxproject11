pub(all) enum Token {
  Ident(String)
  Colon
  Equal
  Pipe
  PipePipe
  Newline
  Indent
  Eof
  Error(String)
} derive(Debug, Eq)

pub impl Show for Token with output(self : Token, logger : &Logger) -> Unit {
  match self {
    Ident(s) => { logger.write_string("Ident("); logger.write_string(s); logger.write_string(")") }
    Colon => logger.write_string("Colon")
    Equal => logger.write_string("Equal")
    Pipe => logger.write_string("Pipe")
    PipePipe => logger.write_string("PipePipe")
    Newline => logger.write_string("Newline")
    Indent => logger.write_string("Indent")
    Eof => logger.write_string("Eof")
    Error(s) => { logger.write_string("Error("); logger.write_string(s); logger.write_string(")") }
  }
}
