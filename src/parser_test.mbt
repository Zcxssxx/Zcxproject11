test "parser basics" {
  let ninja_input =
    #|rule cc
    #|  command = gcc -c $in -o $out
    #|build main.o: cc main.c
    #|
  let p = Parser::new(ninja_input)
  try {
    let manifest = p.parse()
    let graph = DepGraph::build(manifest)
    match graph.traverse("main.o") {
      Ok(edges) => {
        assert_eq(edges.length(), 1)
        assert_eq(edges[0].rule, "cc")
        assert_eq(edges[0].inputs[0], "main.c")
        assert_eq(edges[0].outputs[0], "main.o")
      }
      Err(e) => abort("Traverse failed: " + e)
    }
  } catch {
    _ => abort("Parse failed")
  }
}
