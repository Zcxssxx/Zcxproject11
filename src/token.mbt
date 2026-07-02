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
