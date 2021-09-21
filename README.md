See [website docs](https://cucumber.io/docs/cucumber/cucumber-expressions/) 
for more details.

## Grammar ##

A Cucumber Expression has the following AST:

```ebnf
cucumber-expression :=  ( alternation | optional | parameter | text )*
alternation := (?<=left-boundary) + alternative* + ( '/' + alternative* )+ + (?=right-boundary)
left-boundary := whitespace | } | ^
right-boundary := whitespace | { | $
alternative: = optional | parameter | text 
optional := '(' + option* + ')'
option := optional | parameter | text
parameter := '{' + name* + '}'
name := whitespace | .
text := whitespace | ')' | '}' | .
```

The AST is constructed from the following tokens:
```ebnf
escape := '\'
token := whitespace | '(' | ')' | '{' | '}' | '/' | .
. := any non-reserved codepoint
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

```ebnf
cucumber-expression -> '^' + rewrite(node[0]) + ... + rewrite(node[n-1]) + '$'
alternation -> '(?:' + rewrite(node[0]) +'|' + ...  +'|' + rewerite(node[n-1]) + ')'
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

## Acknowledgements

The Cucumber Expression syntax is inspired by similar expression syntaxes in
other BDD tools, such as [Turnip](https://github.com/jnicklas/turnip), 
[Behat](https://github.com/Behat/Behat) and 
[Behave](https://github.com/behave/behave).

Big thanks to Jonas Nicklas, Konstantin Kudryashov and Jens Engel for
implementing those libraries.

The [Tiny-Compiler-Parser tutorial](https://blog.klipse.tech/javascript/2017/02/08/tiny-compiler-parser.html)
by [Yehonathan Sharvit](https://github.com/viebel) inspired the design of the
Cucumber expression parser. 
