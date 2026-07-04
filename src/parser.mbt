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
  let rules : Map[String, Rule] = {}
  let builds : Array[BuildEdge] = []
  while self.current_token != Eof {
    match self.current_token {
      Ident(kw) => {
        if kw == "rule" {
          self.advance()
          match self.current_token {
            Ident(rule_name) => {
              self.advance()
              if self.current_token == Newline { self.advance() }
              match self.current_token {
                Ident(cmd_kw) => {
                  if cmd_kw == "command" {
                    self.advance()
                    if self.current_token == Equal {
                      self.advance()
                      let cmd = self.lexer.read_rest_of_line()
                      rules[rule_name] = { name: rule_name, command: cmd }
                      self.current_token = self.lexer.next_token()
                    } else {
                      raise SyntaxError("Expected '=' after command", line=self.lexer.line, col=self.lexer.col)
                    }
                  } else {
                    raise SyntaxError("Expected 'command' inside rule", line=self.lexer.line, col=self.lexer.col)
                  }
                }
                _ => raise SyntaxError("Expected command keyword in rule", line=self.lexer.line, col=self.lexer.col)
              }
            }
            _ => raise SyntaxError("Expected rule name after 'rule'", line=self.lexer.line, col=self.lexer.col)
          }
        } else if kw == "build" {
          self.advance()
          let outputs : Array[String] = []
          while self.current_token != Colon && self.current_token != Eof {
            match self.current_token {
              Ident(out) => {
                outputs.push(out)
                self.advance()
              }
              _ => raise SyntaxError("Expected outputs before ':'", line=self.lexer.line, col=self.lexer.col)
            }
          }
          if self.current_token == Colon {
            self.advance()
            match self.current_token {
              Ident(rule_name) => {
                self.advance()
                let inputs : Array[String] = []
                while self.current_token != Newline && self.current_token != Eof {
                  match self.current_token {
                    Ident(inp) => {
                      inputs.push(inp)
                      self.advance()
                    }
                    _ => raise SyntaxError("Expected input after rule name", line=self.lexer.line, col=self.lexer.col)
                  }
                }
                builds.push({ rule: rule_name, inputs, outputs })
              }
              _ => raise SyntaxError("Expected rule name in build statement", line=self.lexer.line, col=self.lexer.col)
            }
          } else {
            raise SyntaxError("Expected ':' in build statement", line=self.lexer.line, col=self.lexer.col)
          }
        } else {
          raise SyntaxError("Unknown top-level keyword: " + kw, line=self.lexer.line, col=self.lexer.col)
        }
      }
      Newline => self.advance()
      _ => raise UnexpectedToken(self.current_token, expected="keyword or newline")
    }
  }
  { rules, builds }
}
