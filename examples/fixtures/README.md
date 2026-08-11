# Committed native fixtures

These files are intentionally small but real C inputs. They are referenced by
the checked-in benchmark manifest and never generated at test time.

- math.c and math.h exercise a compile edge with an explicit header input.
- strings.c exercises a second independent compile edge.
- hello.c is a consumer-style source fixture for a downstream link or
  integration test.

The fixtures are not vendored third-party code. They are original test inputs
under the repository Apache-2.0 license.
