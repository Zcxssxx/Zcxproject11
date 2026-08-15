# Changelog

## 0.3.0 - 2026-08-15

- fixed GitHub Actions push coverage to the canonical `main` branch
- added MoonBit 0.10.3 CI verification
- added deterministic variable expansion with recursion diagnostics
- added Make-style depfile parsing and manifest dependency merging
- added response-file parsing/materialization and structured command lines
- added materialized target plans, target inspection, dependency diffs, and
  portable incremental state sidecars
- added cross-platform path safety and pre-execution command validation
- expanded the real regression suite to 61 portable tests and more than 4,000
  effective tracked MoonBit implementation/test lines

## 0.2.0 - 2026-08-11

- added committed C benchmark fixtures and a medium Ninja workload
- added benchmark summaries for graph size, depth, fan-in/fan-out, and waves
- added manifest validation, parse/graph diagnostics, and plan analysis APIs
- added duplicate-rule and boundary regression coverage
- added a native bounded atomic-index worker pool for independent dependency waves
- added native integration coverage for every committed benchmark input
- expanded the acceptance self-check to verify source scale, fixtures, docs, and closed README checks

## 0.1.2

- published the initial Mooncakes-ready release with parser, graph, incremental,
  host ABI, CI, and acceptance documentation
