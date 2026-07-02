pub suberror ParseError {
  UnexpectedToken(Token, expected~: String)
  SyntaxError(String, line~: Int, col~: Int)
} derive(Debug)
