///|
pub struct Lexer {
  input : String
  mut pos : Int
  mut line : Int
  mut col : Int
}

///|
fn get_char_at(s : String, i : Int) -> Char {
  match s[i].to_int().to_char() {
    Some(c) => c
    None => ' '
  }
}

///|
pub fn Lexer::new(input : String) -> Lexer {
  { input, pos: 0, line: 1, col: 1 }
}

///|
pub fn Lexer::next_token(self : Lexer) -> Token {
  self.skip_whitespace()
  if self.pos >= self.input.length() {
    return Eof
  }
  let ch = get_char_at(self.input, self.pos)
  if ch == '#' {
    self.skip_comment()
    return self.next_token()
  }
  if ch == ':' {
    self.advance()
    return Colon
  }
  if ch == '=' {
    self.advance()
    return Equal
  }
  if ch == '|' {
    self.advance()
    if self.pos < self.input.length() &&
      get_char_at(self.input, self.pos) == '|' {
      self.advance()
      return PipePipe
    }
    return Pipe
  }
  if ch == '\n' {
    self.advance_line()
    return Newline
  }
  self.parse_ident()
}

///|
fn Lexer::advance(self : Lexer) -> Unit {
  self.pos += 1
  self.col += 1
}

///|
fn Lexer::advance_line(self : Lexer) -> Unit {
  self.pos += 1
  self.line += 1
  self.col = 1
}

///|
fn Lexer::skip_whitespace(self : Lexer) -> Unit {
  while self.pos < self.input.length() {
    let ch = get_char_at(self.input, self.pos)
    if ch == ' ' || ch == '\t' || ch == '\r' {
      self.advance()
    } else {
      break
    }
  }
}

///|
fn Lexer::skip_comment(self : Lexer) -> Unit {
  while self.pos < self.input.length() {
    let ch = get_char_at(self.input, self.pos)
    if ch == '\n' {
      break
    }
    self.advance()
  }
}

///|
fn Lexer::parse_ident(self : Lexer) -> Token {
  let start = self.pos
  while self.pos < self.input.length() {
    let ch = get_char_at(self.input, self.pos)
    if (ch >= 'a' && ch <= 'z') ||
      (ch >= 'A' && ch <= 'Z') ||
      (ch >= '0' && ch <= '9') ||
      ch == '_' ||
      ch == '-' ||
      ch == '.' ||
      ch == '$' ||
      ch == '/' {
      self.advance()
    } else {
      break
    }
  }
  if start == self.pos {
    let err_ch = get_char_at(self.input, self.pos)
    self.advance()
    return Error("Unexpected character: \{err_ch}")
  }
  Ident(self.input[start:self.pos].to_owned())
}

///|
pub fn Lexer::read_rest_of_line(self : Lexer) -> String {
  self.skip_whitespace()
  let start = self.pos
  while self.pos < self.input.length() {
    let ch = get_char_at(self.input, self.pos)
    if ch == '\n' {
      break
    }
    self.advance()
  }
  self.input[start:self.pos].to_owned()
}
