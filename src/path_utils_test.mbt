///|
test "path normalization is cross-platform and workspace safe" {
  match normalize_build_path("build\\obj/./../app.o") {
    Ok(path) => assert_eq(path, "build/app.o")
    Err(error) => abort(error)
  }
  assert_true(is_relative_build_path("src/main.c"))
  assert_true(!is_relative_build_path("../outside.c"))
  assert_true(!is_relative_build_path("C:/outside.c"))
}

///|
test "path helpers expose extension stem and directory" {
  assert_eq(build_path_extension("src/main.cpp"), ".cpp")
  assert_eq(build_path_stem("src/main.cpp"), "main")
  assert_eq(build_path_directory("src/main.cpp"), "src")
  assert_eq(build_path_extension("README"), "")
}

///|
test "path join rejects workspace escape" {
  match join_build_path(["build", "..", "..", "outside.o"]) {
    Ok(_) => abort("workspace escape should fail")
    Err(error) => assert_true(error.contains("workspace"))
  }
}
