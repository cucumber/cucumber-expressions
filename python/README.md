# Cucumber Expressions for Python

[Syntax, parameter types, and the playground](https://github.com/cucumber/cucumber-expressions#readme) are in the main docs. This page covers using the Python package.

## Install

```bash
pip install cucumber-expressions
```

## Match text and read captured values

```python
from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry

expression = CucumberExpression("I have {int} cuke(s)", ParameterTypeRegistry())
matches = expression.match("I have 7 cukes")
count = matches[0].value  # 7
```

`match` returns `None` when the text does not match.

Built-in parameter types include `{int}`, `{float}`, `{word}`, `{string}`, and `{}` (anonymous).

## Custom parameter types

```python
from cucumber_expressions.expression import CucumberExpression
from cucumber_expressions.parameter_type import ParameterType
from cucumber_expressions.parameter_type_registry import ParameterTypeRegistry

class Color:
    def __init__(self, name: str):
        self.name = name

registry = ParameterTypeRegistry()
registry.define_parameter_type(
    ParameterType("color", r"red|blue|yellow", Color, lambda s: Color(s), True, False),
)

expression = CucumberExpression("I have a {color} ball", registry)
color = expression.match("I have a red ball")[0].value
```
