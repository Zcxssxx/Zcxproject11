pub(all) struct Manifest {
  rules: Map[String, Rule]
  builds: Array[BuildEdge]
}

pub(all) struct Rule {
  name: String
  command: String
}

pub(all) struct BuildEdge {
  rule: String
  inputs: Array[String]
  outputs: Array[String]
}
