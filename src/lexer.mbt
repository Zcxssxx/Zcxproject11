pub struct Lexer {
  input : String
  mut pos : Int
  mut line : Int
  mut col : Int
}

pub fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, line: 1, col: 1 }
}

pub fn Lexer::next_token(self : Lexer) -> Token {
  self.skip_whitespace()
  if self.pos >= self.input.length() { return Eof }
  let ch = self.input[self.pos]
  if ch == ':' { self.advance(); return Colon }
  if ch == '=' { self.advance(); return Equal }
  if ch == '|' {
    self.advance()
    if self.pos < self.input.length() && self.input[self.pos] == '|' {
      self.advance()
      return PipePipe
    }
    return Pipe
  }
  if ch == '\n' { self.advance_line(); return Newline }
  self.parse_ident()
}

fn Lexer::advance(self : Lexer) -> Unit { self.pos += 1; self.col += 1 }
fn Lexer::advance_line(self : Lexer) -> Unit { self.pos += 1; self.line += 1; self.col = 1 }

fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while self.pos < self.input.length() {
    let ch = self.input[self.pos]
    if ch == ' ' || ch == '\t' || ch == '\r' { self.advance() }
    else { break }
  }
}

fn Lexer::parse_ident(self : Lexer) -> Token {
  let start = self.pos
  while self.pos < self.input.length() {
    let ch = self.input[self.pos]
    if (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '9') || ch == '_' || ch == '-' || ch == '.' {
      self.advance()
    } else { break }
  }
  if start == self.pos {
    let err_ch = self.input[self.pos]
    self.advance()
    return Error("Unexpected character: " + err_ch.to_string())
  }
  Ident(self.input.substring(start~, end=self.pos))
}
