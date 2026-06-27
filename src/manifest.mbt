pub struct Manifest {
  rules: Map[String, Rule]
  builds: Array[BuildEdge]
}

pub struct Rule {
  name: String
  command: String
}

pub struct BuildEdge {
  rule: String
  inputs: Array[String]
  outputs: Array[String]
}
