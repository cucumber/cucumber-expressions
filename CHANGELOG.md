# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [15.1.1] - 2022-04-21
### Fixed
- [JavaScript] Make `CucumberExpression.ast` public (it was accidentally private in 15.1.0)

## [15.1.0] - 2022-04-21
### Added
- [JavaScript] Add `CucumberExpression.ast` and expose the AST types.

## [15.0.2] - 2022-03-15
### Fixed
- Add missing `name` field in CommonJS package file ([#87](https://github.com/cucumber/cucumber-expressions/pull/87))

## [15.0.1] - 2022-01-04
### Fixed
- Fixed release scripts

## [15.0.0] - 2022-01-04
### Added
- [Ruby,JavaScript,Go] Add `bigdecimal`, `biginteger` parameter types ([#42](https://github.com/cucumber/cucumber-expressions/pull/42))
- [.NET] Implementation of Cucumber Expressions by porting the Java parser
([#1743](https://github.com/cucumber/cucumber-expressions/pull/45))
- [Python] Added Python Cucumber Expressions
([#65](https://github.com/cucumber/cucumber-expressions/pull/65))

### Changed
- [Go] Parameters of type `{float}` are now parsed as `float32` (previously it was `float64`).
Use `{double}` if you need `float64`. ([#42](https://github.com/cucumber/cucumber-expressions/pull/42))

## [14.0.0] - 2021-10-12
### Changed
- TypeScript: `Group#value` can no longer be `undefined` ([#16](https://github.com/cucumber/cucumber-expressions/pull/16))
- TypeScript: `Argument` is no longer generic ([#16](https://github.com/cucumber/cucumber-expressions/pull/16))
- Go: Module renamed to match github repository([#24](https://github.com/cucumber/cucumber-expressions/pull/24))

## [13.1.3] - 2021-09-24
### Fixed
- Fix release for the Go implementation

## [13.1.2] - 2021-09-24
### Fixed
- Fix release for the Go implementation
- Minor fixes in the README.md links to documentation

## [13.1.1] - 2021-09-24
### Fixed
- Fix misc release actions

## [13.1.0] - 2021-09-24
### Added
- [JavaScript] Support for EcmaScript modules (aka ESM).
([#1743](https://github.com/cucumber/common/pull/1743))

## [13.0.1] - 2021-09-15
### Changed
- Remove dependency on Node.js APIs (`util` module)
([#1250](https://github.com/cucumber/common/issues/1250)
[#1752](https://github.com/cucumber/common/pull/1752)
[aslakhellesoy](https://github.com/aslakhellesoy))
- Remove dependency on Browser APIs (`window` constant)
([#1752](https://github.com/cucumber/common/pull/1752)
[aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed
- [JavaScript] Correctly match empty strings
([#1329](https://github.com/cucumber/common/issues/1329)
[#1753](https://github.com/cucumber/common/pull/1753)
[aslakhellesoy](https://github.com/aslakhellesoy))

### Removed
- Remove deprecated `CucumberExpressionGenerator#generateExpression` method.
([#1752](https://github.com/cucumber/common/pull/1752))

## [12.1.3] - 2021-09-01
### Fixed
- Use native RegExp Match indices (currently relying on a polyfill)
([#1652](https://github.com/cucumber/common/pull/1652)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [12.1.2] - 2021-08-17
### Changed
- [Go] Move module paths to point to monorepo
([#1550](https://github.com/cucumber/common/issues/1550))
- [Java] Upgraded apiguardian to v1.1.2

## [12.1.1] - 2021-04-06
### Fixed
- [Ruby] use `Array#select` instead of `Array#filter`. The latter is an alias that
was introduced in Ruby [2.6.0](https://github.com/ruby/ruby/blob/v2_6_0/NEWS#core-classes-updates-outstanding-ones-only-).
([aslakhellesoy](https://github.com/aslakhellesoy))

## [12.1.0] - 2021-04-06
### Added
- [Ruby] Add `UndefinedParameterTypeError#undefined_parameter_type_name`
([#1460](https://github.com/cucumber/cucumber/pull/1460)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [12.0.1] - 2021-04-06
### Fixed
- [JavaScript] Fix issue with some files may not appear in published package
([#1452](https://github.com/cucumber/cucumber/pull/1452))
- [Java] Support character in BuiltInParameterTransformer.
([#1405](https://github.com/cucumber/cucumber/issues/1405))

## [12.0.0] - 2021-02-09
### Changed
- [JavaScript] removed circular dependencies.
([#1292](https://github.com/cucumber/cucumber/pull/1292)
[davidjgoss](https://github.com/aslakhellesoy))

## 11.0.2 - 2021-02-09
### Fixed
- [JavaScript] revert breaking changes in 11.0.1
([#1352](https://github.com/cucumber/cucumber/issues/1352))

## [11.0.1] - 2021-02-07
### Fixed
- [JavaScript] removed circular dependencies.
([#1292](https://github.com/cucumber/cucumber/pull/1292)
[davidjgoss](https://github.com/aslakhellesoy))

## [11.0.0] - 2020-12-10
### Added

### Changed
- Some expressions that were valid in previous versions may now be invalid
- Some expressions that were invalid in previous versions may now be valid

### Fixed
- [Go, Java, JavaScript, Ruby] New handwritten parser, which fixes several long-standing bugs.
([#601](https://github.com/cucumber/cucumber/issues/601)
[#726](https://github.com/cucumber/cucumber/issues/726)
[#767](https://github.com/cucumber/cucumber/issues/767)
[#770](https://github.com/cucumber/cucumber/issues/770)
[#771](https://github.com/cucumber/cucumber/pull/771)
[mpkorstanje](https://github.com/mpkorstanje))
- [Go] Support for Go 1.15

### Removed
- [JavaScript] Removed webpacked JavaScript from distribution

## [10.3.0] - 2020-08-07
### Added
- [JavaScript] export `GeneratedExpression`

## [10.2.2] - 2020-07-30
### Fixed
- Use Unicode symbols as a parameter boundary in snippets
([#1108](https://github.com/cucumber/cucumber/pull/1108)
[mpkorstanje](https://github.com/mpkorstanje))

## [10.2.1] - 2020-06-23
### Fixed
- [Java, Go, Ruby, JavaScript] Parse all group variants
([#1069](https://github.com/cucumber/cucumber/pull/1069)
[mpkorstanje](https://github.com/mpkorstanje))
- [Java, Go, Ruby, JavaScript] Retain position of optional groups
([#1076](https://github.com/cucumber/cucumber/pull/1076)
[mpkorstanje](https://github.com/mpkorstanje))

## [10.2.0] - 2020-05-28
### Added
- [Java] Add support for Optional
([#1006](https://github.com/cucumber/cucumber/pull/1006)
[gaeljw](https://github.com/gaeljw), [mpkorstanje](https://github.com/mpkorstanje))
- [Java] Enable consumers to find our version at runtime using `clazz.getPackage().getImplementationVersion()` by upgrading to `cucumber-parent:2.1.0`
([#976](https://github.com/cucumber/cucumber/pull/976)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [10.1.0] - 2020-04-14
### Changed
- [Java] `CucumberExpression` and `RegularExpression` are now public.

### Fixed
- [Java] Minor performance improvement for matching regular expressions steps.

## [10.0.0] - 2020-03-31
### Changed
- [JavaScript] All array return values and function parameters are now declared as TypeScript `ReadOnlyArray`

## [9.0.0] - 2020-02-14
### Added
- [JavaScript, Ruby] Added `ExpressionFactory`, which is now the preferred way to create `Expression` instances.

### Deprecated
- [Ruby] `CucumberExpression` and `RegularExpression` constructors should not be used directly.
Use `ExpressionFactory#create_expression` instead.

### Removed
- [Java, JavaScript] `CucumberExpression` and `RegularExpression` are no longer part of the public API.
- [JavaScript] remove support for Node 8, which is now EOL

## [8.3.1] - 2020-01-10

## [8.3.0] - 2019-12-10
### Added
- [JavaScript] export `Argument`, `Group` and `Expression` types

## [8.2.1] - 2019-11-11
### Fixed
- Fix webpack packaging (simplify by assigning to `window.CucumberExpressions`)

## [8.2.0] - 2019-11-11
### Added
- [JavaScript] build with webpack.
([#792](https://github.com/cucumber/cucumber/pull/792)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [8.1.0] - 2019-10-31
### Added
- Expose `Argument#getParameterType()` method. Needed by Cucumber `protobuf` formatters.
([#781](https://github.com/cucumber/cucumber/pull/781)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [8.0.2] - 2019-10-28
### Fixed
- [Go] Change Go module name to `github.com/cucumber/cucumber-expressions-go/v8`
([aslakhellesoy](https://github.com/aslakhellesoy))
- Fix captured empty strings being undefined
([#746](https://github.com/cucumber/cucumber/issues/746)
[#754](https://github.com/cucumber/cucumber/pull/754)
[davidjgoss](https://github.com/davidjgoss))

## [8.0.1] - 2019-10-07
### Fixed
- [JavaScript] Support Node 8
([#732](https://github.com/cucumber/cucumber/pull/732)
[#725](https://github.com/cucumber/cucumber/issues/725)
[charlierudolph](https://github.com/charlierudolph))

## [8.0.0] - 2019-08-11
### Added
- [Java] Annotate function interfaces with @FunctionalInterface
([cucumber/cucumber-jvm#1716](https://github.com/cucumber/cucumber-jvm/issues/1716)
[mpkorstanje](https://github.com/mpkorstanje))

### Changed
- [Java] Mark public api with @API Guardian annotations
([cucumber/cucumber-jvm#1536](https://github.com/cucumber/cucumber-jvm/issues/1536)
[mpkorstanje](https://github.com/mpkorstanje))
- Improve decimal number parsing
([#669](https://github.com/cucumber/cucumber/issues/669)
[#672](https://github.com/cucumber/cucumber/pull/672)
[#675](https://github.com/cucumber/cucumber/pull/675)
[#677](https://github.com/cucumber/cucumber/pull/677)
[mpkorstanje](https://github.com/mpkorstanje))
- Only suggest parameter types when text is surrounded by whitespace or punctuation
([#657](https://github.com/cucumber/cucumber/issues/657)
[#661](https://github.com/cucumber/cucumber/pull/661)
[vincent-psarga](https://github.com/aslakhellesoy)
[luke-hill](https://github.com/mpkorstanje))
- [Java] Upgrades to `cucumber-parent:2.0.2`
- [Java] Simplify heuristics to distinguish between Cucumber Expressions and Regular Expressions
([#515](https://github.com/cucumber/cucumber/issues/515)
[#581](https://github.com/cucumber/cucumber/pull/581)
[mpkorstanje](https://github.com/mpkorstanje))
- [Java/Go] cucumber-expressions: Prefer language type hint over parameter type
([#658](https://github.com/cucumber/cucumber/pull/658)
[#659](https://github.com/cucumber/cucumber/pull/659)
[mpkorstanje](https://github.com/mpkorstanje))

### Fixed
- Fix RegExp lookaround
([#643](https://github.com/cucumber/cucumber/issues/643)
[#644](https://github.com/cucumber/cucumber/pull/644)
[vincent-psarga](https://github.com/mpkorstanje))
- Match integer strings as `{float}`.
([#600](https://github.com/cucumber/cucumber/issues/600)
[#605](https://github.com/cucumber/cucumber/pull/605)
[aslakhellesoy](https://github.com/vincent-psarga))
- reconized lookaround as a non-capturing regex
([#481](https://github.com/cucumber/cucumber/issues/576)
[#593](https://github.com/cucumber/cucumber/pull/593)
[#643](https://github.com/cucumber/cucumber/pull/643)
[#644](https://github.com/cucumber/cucumber/pull/644)
[luke-hill](https://github.com/luke-hill))

## [7.0.2] - 2019-06-15
### Fixed
- Support Boolean in BuiltInParameterTransformer
([#604](https://github.com/cucumber/cucumber/pull/604) [tommywo](https://github.com/tommywo))

## [7.0.0] - 2019-03-22
### Fixed
- Javascript release process
- Version numbering 🙈

## 6.6.2 - 2019-03-22

## [6.2.3] - 2019-03-22
### Fixed
- Ruby release process working again

## [6.2.2] - 2019-03-16
### Changed
- Limit generated expressions to 256
([#576](https://github.com/cucumber/cucumber/issues/576),
[#574](https://github.com/cucumber/cucumber/pull/574)
[mpkorstanje](https://github.com/mpkorstanje))

### Fixed
- Allow parameter-types in escaped optional groups
([#572](https://github.com/cucumber/cucumber/pull/572),
[#561](https://github.com/cucumber/cucumber/pull/561)
[luke-hill](https://github.com/luke-hill), [jaysonesmith](https://github.com/jaysonesmith), [mpkorstanje](https://github.com/mpkorstanje))
- Prefer expression with the longest non-empty match #580
([#580](https://github.com/cucumber/cucumber/pull/580),
[#575](https://github.com/cucumber/cucumber/issues/575)
[mpkorstanje](https://github.com/mpkorstanje))

## [6.2.1] - 2018-11-30
### Fixed
- (Java) Improve heuristics for creating Cucumber/Regular Expressions from strings
([#515](https://github.com/cucumber/cucumber/issues/515)
[#518](https://github.com/cucumber/cucumber/pull/518)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [6.2.0] - 2018-10-28
### Added
- Add anonymous parameter types
([#496](https://github.com/cucumber/cucumber/pull/496) [mpkorstanje](https://github.com/mpkorstanje))

## [6.1.2] - 2018-10-11

## [6.1.1] - 2018-10-11
### Fixed
- (Java) Add the ability to supply an alternative algorithm for compiling `java.util.regex.Pattern`
to work around a limitation on Android (and other platforms).
([#494](https://github.com/cucumber/cucumber/issues/494)
[#498](https://github.com/cucumber/cucumber/pull/498)
[lsuski](https://github.com/lsuski))

## 6.1.0 - 2018-09-23
### Added
- (Java) Added `ParameterType.fromEnum(MyEnumClass.class)` to make it easier
to register enums.
([#423](https://github.com/cucumber/cucumber/pull/423)
[aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed
- java: The text between `()` (optional text) can be unicode.
([#473](https://github.com/cucumber/cucumber/pull/473)
[savkk](https://github.com/aslakhellesoy)
- The built-in `{word}` parameter type handles unicode (any non-space character)
([#471](https://github.com/cucumber/cucumber/pull/471)
[savkk](https://github.com/aslakhellesoy)
- Parenthesis inside character class should not be treated as capture group.
([#454](https://github.com/cucumber/cucumber/issues/454)
[#461](https://github.com/cucumber/cucumber/pull/461)
[#463](https://github.com/cucumber/cucumber/pull/463)
[#464](https://github.com/cucumber/cucumber/pull/464)
[aidamanna](https://github.com/aslakhellesoy)
[spicalous](https://github.com/spicalous))

### Removed
- java: OSGi support has been removed.
([#412](https://github.com/cucumber/cucumber/issues/412)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [6.0.1] - 2018-06-14
### Added
- Allow `ParameterType` with no name (`nil`, `null`, `""`). Useful when the
Parameter Type is only used in conjunction with Regular Expressions.
([#387](https://github.com/cucumber/cucumber/issues/387)
[#410](https://github.com/cucumber/cucumber/pull/410)
[aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed
- Support empty capture groups.
([#404](https://github.com/cucumber/cucumber/issues/404)
[#411](https://github.com/cucumber/cucumber/pull/411)
[aslakhellesoy](https://github.com/aslakhellesoy))
- Better error message if a parameter type has a name with one of the characters `()[]$.|?*+`.
([#387](https://github.com/cucumber/cucumber/issues/387)
[#410](https://github.com/cucumber/cucumber/pull/410)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [6.0.0] - 2018-05-30
### Changed
- Throw an error if a parameter type is used inside optional text parenthesis,
or with alternative text.
([#360](https://github.com/cucumber/cucumber/pull/360)
[aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed
- Bugfix for nested capture groups.
([#375](https://github.com/cucumber/cucumber/issues/375)
[#380](https://github.com/cucumber/cucumber/pull/380)
[aslakhellesoy](https://github.com/charlierudolph))

## 5.0.19 - 2018-05-24
### Fixed
- java: Escape closing braces to avoid PatternSyntaxException on Android

## [5.0.18] - 2018-05-21
### Changed
- java: The `{byte}` parameter type no longer uses hexadecimal, but uses the same pattern as `{short}`, `{int}` and `{long}`.

### Fixed
- The `/` character can be escaped with `\/` in order to keep a literal `/` rather
than interpreting it as alternation character. Generated expressions will use
`\/` if the original text contains `/`.
([#391](https://github.com/cucumber/cucumber/issues/391)
[#392](https://github.com/cucumber/cucumber/pull/392)
[aslakhellesoy](https://github.com/aslakhellesoy))

## 5.0.17 - 2018-04-12
### Changed
- java: Swapped 2 parameters in a `ParameterType` constructor to make it consistent with
overloaded constructors.

## [5.0.16] - 2018-04-12
### Changed
- java: Renamed `{bigint}` to `{biginteger}` ([mpkorstanje, aslakhellesoy])
- java: The API uses `Transformer` for transforms with 0-1 capture groups,
and `CaptureGroupTransformer` for 2+ capture groups.

### Fixed
- java: Better error message when users leave anchors (^ and $) in their regular expressions ([aslakhellesoy](https://github.com/aslakhellesoy))
- java: `{bigdecimal}` would only match integers ([mpkorstanje, aslakhellesoy])
- java: `{byte}` is suggested in snippets ([mpkorstanje](https://github.com/mpkorstanje))

## [5.0.15] - 2018-04-08
### Added
- go: Added Go implementation
([#350](https://github.com/cucumber/cucumber/pull/350)
[charlierudolph](https://github.com/charlierudolph))

### Changed
- java: Change the Java API
([e246e7c76045f9a379cebe46e40a0f2705c9d82c](https://github.com/cucumber/cucumber-expressions-java/commit/e246e7c76045f9a379cebe46e40a0f2705c9d82c)
[mpkorstanje](https://github.com/mpkorstanje))

## [5.0.14] - 2018-04-04
### Added
- Matching a literal open-parenthesis
([#107](https://github.com/cucumber/cucumber/issues/107)
[#333](https://github.com/cucumber/cucumber/issues/333)
[#334](https://github.com/cucumber/cucumber/pull/334)
[jamis](https://github.com/jamis))
- Matching a literal left curly brace [aslakhellesoy](https://github.com/aslakhellesoy)

### Fixed
- Generated expressions escape `(` and `{` if they were present in the text.
([#345](https://github.com/cucumber/cucumber/issues/345)
[aslakhellesoy](https://github.com/aslakhellesoy))

### Removed
- ruby: Support for named capture group in `Regexp`
([#329](https://github.com/cucumber/cucumber/issues/329)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [5.0.13] - 2018-01-21
### Fixed
- Fixed _yet_ another regression introduced by [#324](https://github.com/cucumber/cucumber/pull/324)
and simplified capture group parsing in `TreeRegexp` to reduce likelihood of more bugs.

## [5.0.12] - 2018-01-19
### Fixed
- javascript: Fixed another regression introduced by [#324](https://github.com/cucumber/cucumber/pull/324)
([#326](https://github.com/cucumber/cucumber/issues/326)
[#327](https://github.com/cucumber/cucumber/pull/327)
[mpkorstanje](https://github.com/aslakhellesoy))

## 5.0.11 - 2018-01-19
### Fixed
- javascript: Fixed a regression introduced by [#324](https://github.com/cucumber/cucumber/pull/324)
([#325](https://github.com/cucumber/cucumber/issues/325)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [5.0.10] - 2018-01-19
### Fixed
- Support escaped backslashes (`\\`) in Regular expressions.
([#323](https://github.com/cucumber/cucumber/issues/323)
[#324](https://github.com/cucumber/cucumber/pull/324)
[aslakhellesoy](https://github.com/aslakhellesoy))

## [5.0.7] - 2017-11-29
### Fixed
- ruby: Only disallow `Regexp::EXTENDED`, `Regexp::IGNORECASE` and `Regexp::MULTILINE` in `ParameterType` regexps. Other flags such as `Regexp::NOENCODING` and `Regexp::FIXEDENCODING` are OK.

## [5.0.6] - 2017-11-28
### Fixed
- javascript: Backport `RegExp#flags` for Node 4.x

## [5.0.5] - 2017-11-28
### Fixed
- ruby: Fix typo in `ParameterType` error message.
([#306](https://github.com/cucumber/cucumber/issues/306)
[aslakhellesoy](https://github.com/aslakhellesoy), [luke-hill](https://github.com/luke-hill))
- Ignore `ParameterType`s with optional capture groups when generating snippets. Trying to do so
caused an infinite loop.
([#307](https://github.com/cucumber/cucumber/issues/307)
[aslakhellesoy](https://github.com/aslakhellesoy))
- Throw an error when `ParameterType` regexps have flags. Flags are not allowed because only the source
of the regexp is used to build a new regexp for the entire Cucumber Expression. See
[#308](https://github.com/cucumber/cucumber/issues/308). ([aslakhellesoy](https://github.com/aslakhellesoy))

## [5.0.4] - 2017-11-28
### Fixed
- Cucumber Expressions with alternation (`I said Alpha1/Beta1`) now works with
more than just letters - it works with anything that isn't a space.
([#303](https://github.com/cucumber/cucumber/issues/303)
by [aslakhellesoy](https://github.com/aslakhellesoy))

## 5.0.3 - 2017-11-06
### Fixed
- javascript: Support RegExp flags
([#300](https://github.com/cucumber/cucumber/issues/300)
by [aslakhellesoy](https://github.com/aslakhellesoy) and [dmeehan1968](https://github.com/dmeehan1968))

## [5.0.2] - 2017-10-20
### Fixed
- java: Make the jar a bundle to support osgi. ([#287](https://github.com/cucumber/cucumber/pull/287)
by [mpkorstanje](https://github.com/mpkorstanje))

## 5.0.0 - 2017-10-10
### Changed
- ruby, javascript: A `transformer` function can run in the context of a world object. `Argument#value` now takes an object as argument (renamed to `Argument#getValue` in js) ([#284](https://github.com/cucumber/cucumber/pull/284) by [aslakhellesoy](https://github.com/aslakhellesoy))

## [4.0.4] - 2017-10-05
### Changed
- java: Backport to Java 7 ([#1](https://github.com/cucumber/cucumber-expressions-java/pull/1) by [mpkorstanje](https://github.com/mpkorstanje))

### Fixed
- Support `%` in undefined steps so snippet generation doesn't crash. ([#276](https://github.com/cucumber/cucumber/issues/276), [#279](https://github.com/cucumber/cucumber/pull/279) by [aslakhellesoy](https://github.com/aslakhellesoy))
- Support escaped parenthesis in Regular expressions ([#254](https://github.com/cucumber/cucumber/pull/254) by [jaysonesmith](https://github.com/jaysonesmith), [aslakhellesoy](https://github.com/aslakhellesoy))

## [4.0.3] - 2017-07-24
### Fixed
- javascript: Expose `Argument.group` and fix `start` and `end` accessors in `Group`

## 4.0.2 - 2017-07-14
### Fixed
- javascript: Make it work on Node 4 and browser (Use `Array.indexOf` instead of `Array.includes`)
([#237](https://github.com/cucumber/cucumber/pull/237)
by [aslakhellesoy](https://github.com/aslakhellesoy))

## [4.0.1] - 2017-07-14
### Fixed
- Fix bugs with nested and optional capture groups
([#237](https://github.com/cucumber/cucumber/pull/237)
by [aslakhellesoy](https://github.com/aslakhellesoy))

## [4.0.0] - 2017-06-28
### Added
- Support capture groups in parameter types
([#227](https://github.com/cucumber/cucumber/pull/227)
[#57](https://github.com/cucumber/cucumber/issues/57)
[#204](https://github.com/cucumber/cucumber/issues/204)
[#224](https://github.com/cucumber/cucumber/issues/224)
by [aslakhellesoy](https://github.com/aslakhellesoy))
- Add `{word}` built-in parameter type
([#191](https://github.com/cucumber/cucumber/issues/191)
[#226](https://github.com/cucumber/cucumber/pull/226)
by [aslakhellesoy](https://github.com/aslakhellesoy))
- Add `{string}` built-in parameter type
([#190](https://github.com/cucumber/cucumber/issues/190)
[#231](https://github.com/cucumber/cucumber/pull/231)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Changed
- Allow duplicate regexps in parameter types
([#186](https://github.com/cucumber/cucumber/pull/186)
[#132](https://github.com/cucumber/cucumber/issues/132)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed
- RegularExpression constructor is not filtering non-capturing groups
([#211](https://github.com/cucumber/cucumber/issues/211)
[#179](https://github.com/cucumber/cucumber/pull/179)
[#216](https://github.com/cucumber/cucumber/pull/216)
[#220](https://github.com/cucumber/cucumber/pull/220)
by [kAworu](https://github.com/kAworu), [aslakhellesoy](https://github.com/aslakhellesoy))

### Removed
- Remove support for `{name:type}` syntax which was deprecated in
[#117](https://github.com/cucumber/cucumber/pull/117) and released in 2.0.0.
([#180](https://github.com/cucumber/cucumber/pull/180)
by [aslakhellesoy](https://github.com/aslakhellesoy))
- Removed support for `{undefined}` parameter types. If a parameter type is not
defined, and error will be raised.

## [3.0.0] - 2017-03-08
### Added
- Alternative text: `I have a cat/dog/fish`
(by [aslakhellesoy](https://github.com/aslakhellesoy))
- `type` / `constructorFunction`: Makes it simpler to use in languages without static types
- `transform`: Leave arguments unchanged, return as string
(by [aslakhellesoy](https://github.com/aslakhellesoy))
- `ParameterType` can be constructed with `null`/`nil` arguments for

### Changed
- `Parameter         -> ParameterType`
- `ParameterRegistry -> ParameterTypeRegistry`
- `addParameter      -> defineParameterType`
- Renamed API:
- Stricter conflict checks when defining parameters
([#121](https://github.com/cucumber/cucumber/pull/121)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed

### Removed
- java: Drop support for Java 7 (Java 8 or higher is required)

## [2.0.1] - 2017-02-17
### Added
- Document how to define `async` parameters.
Depends on [cucumber/cucumber-js#753](https://github.com/cucumber/cucumber-js/pull/753).
([#108](https://github.com/cucumber/cucumber/issues/108)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Changed
- Defer parameter transformation until after the match
([#118](https://github.com/cucumber/cucumber/issues/118)
[#120](https://github.com/cucumber/cucumber/pull/120)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed
- Tweak Babel settings to produce ES5 code
([#119](https://github.com/cucumber/cucumber/issues/119)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Removed

## [2.0.0] - 2017-02-17
### Added

### Changed
- Deprecate `{name:type}` syntax in favour of `{type}`
([#117](https://github.com/cucumber/cucumber/pull/117)
by [aslakhellesoy](https://github.com/aslakhellesoy))
- Rename transform to parameter
([#114](https://github.com/cucumber/cucumber/issues/114)
[#115](https://github.com/cucumber/cucumber/pull/115)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Fixed
- Escape RegExp characters.
([#103](https://github.com/cucumber/cucumber/issues/103)
[#106](https://github.com/cucumber/cucumber/pull/106)
by [charlierudolph](https://github.com/charlierudolph) and [aslakhellesoy](https://github.com/aslakhellesoy))
- Regexp literals in transforms.
([#109](https://github.com/cucumber/cucumber/issues/109)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Removed

## [1.0.4] - 2017-01-20
### Added

### Changed
- ruby: Use `Integer` instead of `Fixnum`

### Fixed
- Handle multiple capture group regexps for matching
([#102](https://github.com/cucumber/cucumber/issues/102)
by [gpichot](https://github.com/gpichot))
- Make the tests pass on Ruby 2.4.0 (as well as older rubies)

### Removed

## [1.0.3] - 2016-11-25
### Added

### Changed

### Fixed
- Include `dist` in npm package.
([#85](https://github.com/cucumber/cucumber/issues/85)
by [aslakhellesoy](https://github.com/aslakhellesoy))

### Removed

## [1.0.2] - 2016-11-23
### Added

### Changed

### Fixed
- Generated expressions - expose argument names.
([#83](https://github.com/cucumber/cucumber/pull/83)
by [charlierudolph](https://github.com/charlierudolph))
- Build JavaScript code with Babel.
([#86](https://github.com/cucumber/cucumber/pull/86)
by [aslakhellesoy](https://github.com/aslakhellesoy))
- Handle optional groups in regexp.
([#87](https://github.com/cucumber/cucumber/pull/87)
by [brasmusson](https://github.com/brasmusson))

### Removed

## [1.0.1] - 2016-09-28
### Added
- First stable release!

[Unreleased]: https://github.com/cucumber/cucumber-expressions/compare/v15.1.1...HEAD
[15.1.1]: https://github.com/cucumber/cucumber-expressions/compare/v15.1.0...v15.1.1
[15.1.0]: https://github.com/cucumber/cucumber-expressions/compare/v15.0.2...v15.1.0
[15.0.2]: https://github.com/cucumber/cucumber-expressions/compare/v15.0.1...v15.0.2
[15.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v15.0.0...v15.0.1
[15.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v14.0.0...v15.0.0
[14.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v13.1.3...v14.0.0
[13.1.3]: https://github.com/cucumber/cucumber-expressions/compare/v13.1.2...v13.1.3
[13.1.2]: https://github.com/cucumber/cucumber-expressions/compare/v13.1.1...v13.1.2
[13.1.1]: https://github.com/cucumber/cucumber-expressions/compare/v13.1.0...v13.1.1
[13.1.0]: https://github.com/cucumber/cucumber-expressions/compare/v13.0.1...v13.1.0
[13.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v12.1.3...v13.0.1
[12.1.3]: https://github.com/cucumber/cucumber-expressions/compare/v12.1.2...v12.1.3
[12.1.2]: https://github.com/cucumber/cucumber-expressions/compare/v12.1.1...v12.1.2
[12.1.1]: https://github.com/cucumber/cucumber-expressions/compare/v12.1.0...v12.1.1
[12.1.0]: https://github.com/cucumber/cucumber-expressions/compare/v12.0.1...v12.1.0
[12.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v12.0.0...v12.0.1
[12.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v11.0.2...v12.0.0
[11.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v11.0.0...v11.0.1
[11.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v10.3.0...v11.0.0
[10.3.0]: https://github.com/cucumber/cucumber-expressions/compare/v10.2.2...v10.3.0
[10.2.2]: https://github.com/cucumber/cucumber-expressions/compare/v10.2.1...v10.2.2
[10.2.1]: https://github.com/cucumber/cucumber-expressions/compare/v10.2.0...v10.2.1
[10.2.0]: https://github.com/cucumber/cucumber-expressions/compare/v10.1.0...v10.2.0
[10.1.0]: https://github.com/cucumber/cucumber-expressions/compare/v10.0.0...v10.1.0
[10.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v9.0.0...v10.0.0
[9.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v8.3.1...v9.0.0
[8.3.1]: https://github.com/cucumber/cucumber-expressions/compare/v8.3.0...v8.3.1
[8.3.0]: https://github.com/cucumber/cucumber-expressions/compare/v8.2.1...v8.3.0
[8.2.1]: https://github.com/cucumber/cucumber-expressions/compare/v8.2.0...v8.2.1
[8.2.0]: https://github.com/cucumber/cucumber-expressions/compare/v8.1.0...v8.2.0
[8.1.0]: https://github.com/cucumber/cucumber-expressions/compare/v8.0.2...v8.1.0
[8.0.2]: https://github.com/cucumber/cucumber-expressions/compare/v8.0.1...v8.0.2
[8.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v8.0.0...v8.0.1
[8.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v7.0.2...v8.0.0
[7.0.2]: https://github.com/cucumber/cucumber-expressions/compare/v7.0.1...v7.0.2
[7.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v6.2.3...v7.0.0
[6.2.3]: https://github.com/cucumber/cucumber-expressions/compare/v6.2.2...v6.2.3
[6.2.2]: https://github.com/cucumber/cucumber-expressions/compare/v6.2.1...v6.2.2
[6.2.1]: https://github.com/cucumber/cucumber-expressions/compare/v6.2.0...v6.2.1
[6.2.0]: https://github.com/cucumber/cucumber-expressions/compare/v6.1.2...v6.2.0
[6.1.2]: https://github.com/cucumber/cucumber-expressions/compare/v6.1.1...v6.1.2
[6.1.1]: https://github.com/cucumber/cucumber-expressions/compare/v6.0.1...v6.1.1
[6.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.19...v6.0.0
[5.0.18]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.16...v5.0.18
[5.0.16]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.15...v5.0.16
[5.0.15]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.14...v5.0.15
[5.0.14]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.13...v5.0.14
[5.0.13]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.12...v5.0.13
[5.0.12]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.10...v5.0.12
[5.0.10]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.7...v5.0.10
[5.0.7]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.6...v5.0.7
[5.0.6]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.5...v5.0.6
[5.0.5]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.4...v5.0.5
[5.0.4]: https://github.com/cucumber/cucumber-expressions/compare/v5.0.2...v5.0.4
[5.0.2]: https://github.com/cucumber/cucumber-expressions/compare/v4.0.4...v5.0.2
[4.0.4]: https://github.com/cucumber/cucumber-expressions/compare/v4.0.3...v4.0.4
[4.0.3]: https://github.com/cucumber/cucumber-expressions/compare/v4.0.1...v4.0.3
[4.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v4.0.0...v4.0.1
[4.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v3.0.0...v4.0.0
[3.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v2.0.1...v3.0.0
[2.0.1]: https://github.com/cucumber/cucumber-expressions/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/cucumber/cucumber-expressions/compare/v1.0.4...v2.0.0
[1.0.4]: https://github.com/cucumber/cucumber-expressions/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/cucumber/cucumber-expressions/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/cucumber/cucumber-expressions/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/cucumber/cucumber/releases/tag/v1.0.1
