using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace CucumberExpressions;

public class UndefinedParameterTypeException : CucumberExpressionException {
    private readonly String undefinedParameterTypeName;

    public UndefinedParameterTypeException(String message, String undefinedParameterTypeName) : base(message) {
        this.undefinedParameterTypeName = undefinedParameterTypeName;
    }

    public String getUndefinedParameterTypeName() {
        return undefinedParameterTypeName;
    }

    public static CucumberExpressionException createUndefinedParameterType(Ast.Node node, String expression, String undefinedParameterTypeName) {
        return new UndefinedParameterTypeException(message(
                node.start,
                expression,
                pointAt(node),
                "Undefined parameter type '" +undefinedParameterTypeName+ "'",
                "Please register a ParameterType for '"+undefinedParameterTypeName+"'"), undefinedParameterTypeName);
    }
}
