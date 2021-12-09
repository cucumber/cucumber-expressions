Goal: Rewrite the cucumber-expressions parser.

Cucumber-expressions has three parts:
* Lexer/Tokenizer (`String -> Token[]`) - turns a cucumber expression string into tokens
* Parser - makes an AST from the tokens
* Compiler - turns the AST into a regular expression

String -> String

String -> Token[]

`hello world` -> 'h`, 'e', ect
`hello world` -> `hello`, ` `, `world`

'(' = BEGIN_OPTIONAL
')' = END_OPTIONAL
'{' = BEGIN_PARAMETER
'}' = END_PARAMETER
'/' = ALTERNATION
'\' = ESCAPE
' ' = SPACE
.   = TEXT

`hello world` -> `{text: hello, type: TEXT`, `text: ' ', type: SPACE `, ect.



Tokens[] -> Ast
Ast -> String

Today's focus: the lexer/tokenizer

## EBNF


```ebnf
cucumber-expression     = (alternation
                           | optional
                           | parameter
                           | text)*
text                    = (- text-to-escape) | ('\', text-to-escape)
text-to-escape          = '(' | '{' | '/' | '\' 

alternation             = single-alternation, ('/', single_alternation)+
single-alternation      = ((text-in-alternative+, optional*) 
                            | (optional+, text-in-alternative+))+
text-in-alternative     = (- alternative-to-escape) | ('\', alternative-to-escape)
alternative-to-escape   = ' ' | '(' | '{' | '/' | '\'

optional                = '(', text-in-optional+, ')'
text-in-optional        = (- optional-to-escape) | ('\', optional-to-escape)
optional-to-escape      = '(' | ')' | '{' | '/' | '\'

parameter               = '{', name*, '}'
name                    = (- name_to_escape) | ('\', name-to-escape)
name-to-escape          = '{' | '}' | '(' | '/' | '\'
```