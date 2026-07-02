pub struct Parser {
  lexer : Lexer
  mut current_token : Token
}

pub fn Parser::new(input : String) -> Parser {
  let lexer = Lexer::new(input)
  let current_token = lexer.next_token()
  { lexer, current_token }
}

fn Parser::advance(self : Parser) -> Unit {
  self.current_token = self.lexer.next_token()
}

pub fn Parser::parse(self : Parser) -> Manifest raise ParseError {
  let rules = {}
  let builds = []
  while self.current_token != Eof {
    match self.current_token {
      Ident(kw) => {
        if kw == "rule" {
          self.advance()
        } else if kw == "build" {
          self.advance()
        } else {
          raise SyntaxError("Unknown keyword: " + kw, line=self.lexer.line, col=self.lexer.col)
        }
      }
      Newline => self.advance()
      _ => raise UnexpectedToken(self.current_token, expected="keyword or newline")
    }
  }
  { rules, builds }
}
