# Plan: Elixir port of Cucumber Expressions

An Elixir implementation of Cucumber Expressions, hosted in a fork of
`cucumber/cucumber-expressions` under the `oselvar` GitHub org, to be consumed by
**Varar** (the Elixir port of Vár). All AI-generated code stays in the fork; the
upstream Cucumber repo receives nothing.

## Decisions (from interview, 2026-07-17)

| Topic | Decision |
| --- | --- |
| Repo shape | True fork of `cucumber/cucumber-expressions` in the oselvar org; keep all existing language dirs, add `elixir/` alongside |
| Scope | Full parity: tokenizer, parser, CucumberExpression, RegularExpression, TreeRegexp, ParameterType + registry, CucumberExpressionGenerator |
| API style | Idiomatic Elixir: structs + module functions, `{:ok, _}`/`{:error, _}` with `!` variants |
| Namespace | `Varar.CucumberExpressions` |
| Registry | Pure functional — plain struct threaded through calls, no processes |
| Toolchain | Elixir ~> 1.15, OTP 26+; `mix format --check-formatted`, Credo, Dialyzer, ExDoc |
| Hex package | `varar_cucumber_expressions` |
| Versioning | Track upstream major — start at **20.0.0** (upstream's current version) |
| Numerics | `{bigdecimal}` → `%Decimal{}` via the `decimal` Hex package; `{float}`/`{double}` → Elixir floats; `{int}`/`{biginteger}` → native (arbitrary-precision) integers |
| Deliverable | This plan first; scaffold/implementation after review |

## Reference implementations

- **Go port** (`go/`): flat, complete, and the clearest to transliterate from —
  especially `cucumber_expression_tokenizer.go`, `cucumber_expression_parser.go`,
  `tree_regexp.go`/`group_builder.go`, and `parameter_type_registry.go`.
- **Ruby port** (`ruby/`): closest semantic match (dynamic typing,
  arbitrary-precision integers, exception messages) and the model for how specs
  load the shared `testdata/` corpus.
- `ARCHITECTURE.md`: the EBNF grammar both tokenizer and parser must honor.

## Module map

All under `elixir/lib/varar/cucumber_expressions/` (namespace
`Varar.CucumberExpressions`, aliased below as `CE`):

| Module | Ports | Responsibility |
| --- | --- | --- |
| `CE` (facade) | `ExpressionFactory` | `compile/2` (auto-detects `/regex/` vs cucumber expression, like the factory in other ports), `match/2`, convenience re-exports |
| `CE.Tokenizer` | `*_tokenizer` | `tokenize(source) :: {:ok, [Token.t()]} \| {:error, Error.t()}` |
| `CE.Token` | `ast.go` Token | struct: `type` (atom), `text`, `start`, `end`; helpers for symbol/purpose names used in error messages |
| `CE.Parser` | `*_parser` | `parse(source) :: {:ok, Node.t()} \| {:error, Error.t()}` |
| `CE.Node` | `ast.go` Node | struct: `type` (atom), `nodes`, `token`, `start`, `end`; `text/1` |
| `CE.CucumberExpression` | `cucumber_expression.*` | struct: `source`, `tree_regexp`, `parameter_types` (in match order); `compile(source, registry)`, `compile!/2`, `match(expr, text) :: [Argument.t()] \| nil` |
| `CE.RegularExpression` | `regular_expression.*` | struct: `regex`, `tree_regexp`, `registry`; same `match/2` contract; parameter type lookup by capture-group regexp |
| `CE.Expression` (protocol) | `expression.go` | `match/2`, `regex/1`, `source/1` — implemented by both expression structs, so Varar can hold either |
| `CE.ParameterType` | `parameter_type.*` | struct: `name`, `regexps`, `type`, `transformer` (fun), `use_for_snippets`, `prefer_for_regexp_match`; `new/1` validates name legality (same rules/messages as upstream) |
| `CE.ParameterTypeRegistry` | `parameter_type_registry.*` | struct wrapping lookup maps; `new/0` installs built-ins (`int`, `float`, `word`, `string`, `""` anonymous, `bigdecimal`, `double`, `biginteger`, `byte`, `short`, `long`); `add(registry, type) :: {:ok, t} \| {:error, Error.t()}` + `add!/2`; duplicate/preferential-conflict rules ported exactly |
| `CE.TreeRegexp` | `tree_regexp.*` | Walks the regex **source** to build a `GroupBuilder` tree (capture vs non-capture groups, char classes, escapes), compiles with `Regex.compile!(source, "u")`, and on match produces a `Group` tree from `:re`-style all-submatch indices |
| `CE.GroupBuilder`, `CE.Group` | same | tree construction / matched-group values with start/end/children |
| `CE.Argument` | `argument.*` | `build(group, parameter_types)` pairs groups with types; `value/1` applies the transformer |
| `CE.Generator` | `cucumber_expression_generator.*` | `generated_expressions(registry, text)`; plus `CE.ParameterTypeMatcher`, `CE.GeneratedExpression`, `CE.CombinatorialGeneratedExpressionFactory` |
| `CE.Error` | `errors.*` | `defexception` carrying `message` (and optionally `index`/`node`); constructor functions reproduce upstream messages **byte-for-byte** (`build_message`/`point_at_located` helpers), since the matching testdata asserts exact strings |

### API sketch

```elixir
alias Varar.CucumberExpressions, as: CE

registry = CE.ParameterTypeRegistry.new()

{:ok, registry} =
  CE.ParameterTypeRegistry.add(
    registry,
    CE.ParameterType.new!(
      name: "color",
      regexps: ["red|blue|yellow"],
      transformer: &String.to_atom/1
    )
  )

{:ok, expr} = CE.compile("I have {int} {color} cuke(s)", registry)

case CE.Expression.match(expr, "I have 7 blue cukes") do
  nil -> :no_match
  args -> Enum.map(args, &CE.Argument.value/1)  # => [7, :blue]
end
```

Design notes:

- `match/2` returns `[Argument.t()] | nil` — mirroring `Regex.run/2`'s
  `list | nil` idiom; "no match" is not an error. `{:error, _}` is reserved for
  invalid expressions/parameter types at compile/registration time.
- Transformers are 1-arity for the common case (single group) but may accept a
  list when the parameter type has multiple capture groups — resolve by arity
  introspection (`:erlang.fun_info(f, :arity)`), like the JS port's varargs.
- Everything is immutable; Varar owns and threads the registry value.

## Shared testdata harness

Follow the established convention: tests are **generated from
`../testdata/**/*.yaml`**, one ExUnit test per file (named after the file path,
like the Ruby specs). Loader in `test/support/testdata.ex`; YAML via
`yaml_elixir` (test-only dep).

| Suite | Files | Assertion |
| --- | --- | --- |
| `cucumber-expression/tokenizer` | `expression` → `expected_tokens` or `exception` | token list as maps (`type` string ↔ atom mapping), `start`/`end`/`text`; exact exception message |
| `cucumber-expression/parser` | `expression` → `expected_ast` or `exception` | AST serialized back to the YAML map shape and compared structurally |
| `cucumber-expression/transformation` | `expression` → `expected_regex` | generated regex **source string** equality |
| `cucumber-expression/matching` | `expression`, `text` → `expected_args` or `exception` | transformed arg values vs YAML values; like Ruby: `%Decimal{}` compared via `Decimal.to_string/1`, integers > 64 bits compared as strings (testdata encodes bigints as strings) |
| `regular-expression/matching` | `expression` (regex), `text` → `expected_args` | args via anonymous/looked-up types |

Suites without shared testdata (TreeRegexp, custom parameter types, registry
conflicts, Generator, Argument) get hand-ported ExUnit tests translated
case-by-case from the Ruby specs (`ruby/spec/cucumber/cucumber_expressions/*`),
which are the most complete.

### Engine & Unicode caveats

- **Positions are codepoint indices.** Elixir's `String` functions are
  grapheme-based; the tokenizer must operate on a codepoint list
  (`String.to_charlist/1` or `:unicode` conversion) so `start`/`end` match the
  testdata for non-ASCII input (there are emoji/unicode-whitespace fixtures).
- **Regex engine is PCRE** (Erlang `:re`), close to Ruby's engine and strictly
  more capable than Go's RE2, so upstream's built-in regexps (including the
  lookaround-free float regexp) should work unmodified. Compile with the `u`
  flag. TreeRegexp's source-walker must handle `(?:`, `(?=`, `(?!`, `(?<name>`,
  inline flags `(?i)`, char classes, and escapes exactly as the Go/Ruby walkers
  do.
- `Regex.compile/2` errors (e.g. from a user's broken custom regexp) are wrapped
  in `CE.Error` with the upstream-style message.

## Project layout in the fork

```
elixir/
  mix.exs               # app :varar_cucumber_expressions, version "20.0.0"
  .formatter.exs
  .credo.exs
  Makefile              # default: format-check + credo + dialyzer + mix test (mirrors go/Makefile's default target style)
  README.md             # usage docs, follows other ports' README structure
  LICENSE               # MIT, copied like other port dirs
  lib/varar/cucumber_expressions.ex
  lib/varar/cucumber_expressions/*.ex
  test/support/testdata.ex
  test/varar/cucumber_expressions/*_test.exs
```

Dependencies: `decimal ~> 2.0` (runtime); `yaml_elixir`, `credo`, `dialyxir`,
`ex_doc`, `excoveralls` (dev/test only).

CI (in the fork only, modeled on `test-go.yml`):

- `.github/workflows/test-elixir.yml` — `erlef/setup-beam`, matrix
  {Elixir 1.15/OTP 26, latest stable}, `paths: [elixir/**, testdata/**, .github/**]`,
  runs the Makefile default target. Ubuntu is enough initially.
- `.github/workflows/release-hex.yaml` — publish `varar_cucumber_expressions`
  on tag, modeled on `release-rubygem.yaml` (uses `HEX_API_KEY` secret).

## Milestones

Each milestone ends green on its testdata suite — the suites are ordered so
every stage has an executable acceptance test.

1. **Scaffold** — fork repo, `mix new`, testdata loader wired up (generating
   pending tests proves the harness sees all YAML files), CI workflow.
2. **Tokenizer** — port from Go; pass `cucumber-expression/tokenizer` (incl.
   exact error messages for e.g. `escaped-end-of-line.yaml`).
3. **Parser** — AST + parser; pass `cucumber-expression/parser`.
4. **ParameterType + Registry + rewrite to regex** — built-in types, name
   validation, expression → regex rewriting with all validation errors
   (undefined parameter, alternation/optional rules); pass
   `cucumber-expression/transformation`.
5. **TreeRegexp + Group + Argument + matching** — pass both
   `cucumber-expression/matching` and `regular-expression/matching`; port the
   Ruby `tree_regexp_spec` and `argument_spec` by hand.
6. **RegularExpression + factory + custom types** — `CE.compile/2` auto-detect;
   port `custom_parameter_type_spec`, `parameter_type_registry_spec`,
   `expression_factory_spec`.
7. **Generator** — snippet generation chain; port the three generator specs.
8. **Polish & release** — Dialyzer clean, Credo strict, ExDoc with doctests for
   the README examples, coverage report, publish `20.0.0` to Hex, README table
   entry in the fork's root README listing Elixir among the ports.

Rough effort: milestones 2–5 are the bulk; the Go port's flat files make
transliteration mechanical, with the real care going into byte-exact error
messages and codepoint indexing.

## Upstream sync strategy

- Keep `upstream` remote pointing at `cucumber/cucumber-expressions`; the fork
  only ever **adds** `elixir/` + two workflows, so `git merge upstream/main`
  stays conflict-free.
- After each merge, a failing `testdata/` suite is the signal that upstream
  changed the spec; fix the Elixir port to match and cut a Hex release tracking
  the new upstream version.
- Testdata bugs or grammar findings can go upstream as issues/testdata PRs
  (non-code contributions), keeping AI-generated Elixir code out of Cucumber.

## Risks / watch-list

- **Byte-exact error messages** are part of the conformance surface — keep a
  single `build_message` helper so pointer carets (`^-...-^`) and column math
  live in one place, ported from Go's `errors.go`.
- **PCRE vs Ruby-regex edge cases** in user-supplied regexps (`\A` vs `^`,
  possessive quantifiers) — PCRE supports these; only document, don't translate.
- **Named capture groups**: upstream raises a specific error when a
  `RegularExpression` uses them in some ports — follow the Ruby behavior and its
  message.
- **Registry determinism**: Go uses sorted structures for “preferential” type
  resolution ambiguity errors; use sorted lists rather than relying on map
  order so error messages list types in the same order as other ports.
- **Decimal comparison** in the matching suite: compare via `Decimal.to_string`
  (testdata stores bigdecimals as strings), mirroring the Ruby spec's
  special-casing.
- Future: a process-backed registry wrapper can be layered in Varar if a
  global-config ergonomics need appears; not part of this library.
