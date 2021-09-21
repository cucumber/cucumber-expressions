# Architecture

This document describes the grammar and production rules of Cucumber Expressions.

## Grammar

A Cucumber Expression has the following [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form) grammar:

```ebnf
cucumber-expression = ( alternation | optional | parameter | text )*
alternation         = (?<=left-boundary), alternative*, ( "/" + alternative* )+, (?=right-boundary)
left-boundary       = whitespace | "}" | "^"
right-boundary      = whitespace | "{" | "$"
alternative         = optional | parameter | text
optional            = "(", option*, ")"
option              = optional | parameter | text
parameter           = "{", name*, "}"
name                = whitespace | .
text                = whitespace | ")" | "}" | .
```

The AST is constructed from the following tokens:

```ebnf
escape = "\"
token = whitespace | "(" | ")" | "{" | "}" | "/" | .
. = any non-reserved codepoint
```

Note:
 * While `parameter` is allowed to appear as part of `alternative` and
  `option` in the AST, such an AST is not a valid a Cucumber Expression.
 * While `optional` is allowed to appear as part of `option` in the AST,
   such an AST is not a valid a Cucumber Expression.
 * ASTs with empty alternatives or alternatives that only
   contain an optional are valid ASTs but invalid Cucumber Expressions.
 * All escaped tokens (tokens starting with a backslash) are rewritten to their
   unescaped equivalent after parsing.

### Production Rules

The AST can be rewritten into a regular expression by the following production
rules:

```
cucumber-expression -> '^' + rewrite(node[0]) + ... + rewrite(node[n-1]) + '$'
alternation -> '(?:' + rewrite(node[0]) + '|' + ...  + '|' + rewerite(node[n-1]) + ')'
alternative -> rewrite(node[0]) + ... + rewrite(node[n-1])
optional -> '(?:' + rewrite(node[0]) + ... + rewrite(node[n-1]) + ')?'
parameter -> {
     parameter_name := node[0].text + ... + node[n-1].text
     parameter_pattern := parameter_type_registry[parameter_name]
    '((?:' + parameter_pattern[0] + ')|(?:' ... + ')|(?:' + parameter_pattern[n-1] +  '))'
}
text -> {
 escape_regex := escape '^', `$`, `[`, `]`, `(`, `)` `\`, `{`, `}`,  `.`, `|`, `?`, `*`, `+`
 escape_regex(token.text)
}
```
