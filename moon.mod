name = "Zcxssxx/moon-ninja"

version = "0.1.1"

license = "Apache-2.0"

repository = "https://github.com/Zcxssxx/Zcxproject11"

readme = "README.md"

description = "MoonNinja is a MoonBit-native subset Ninja parser and build scheduler with dependency graph planning, incremental analysis, and execution demos."

keywords = [ "moonbit", "ninja", "build-system", "dag", "incremental-build" ]

preferred_target = "wasm-gc"

supported_targets = "+native+wasm+wasm-gc+js"

source = "src"

options(
  exclude: [ "_build", "target" ],
)
