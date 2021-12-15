using System;
using System.Collections.Generic;
using System.Linq;

namespace CucumberExpressions.Generation;

internal class CombinatorialGeneratedExpressionFactory
{
    // 256 generated expressions ought to be enough for anybody
    private const int MAX_EXPRESSIONS = 256;
    private readonly string _expressionTemplate;
    private readonly List<List<IParameterType>> _parameterTypeCombinations;

    public CombinatorialGeneratedExpressionFactory(string expressionTemplate,
            List<List<IParameterType>> parameterTypeCombinations)
    {
        _expressionTemplate = expressionTemplate;
        _parameterTypeCombinations = parameterTypeCombinations;
    }

    public GeneratedExpression[] GenerateExpressions()
    {
        var generatedExpressions = new List<GeneratedExpression>();
        var permutation = new Stack<IParameterType>(_parameterTypeCombinations.Count);
        GeneratePermutations(generatedExpressions, permutation);
        return generatedExpressions.ToArray();
    }

    private void GeneratePermutations(List<GeneratedExpression> generatedExpressions,
            Stack<IParameterType> permutation)
    {
        if (generatedExpressions.Count >= MAX_EXPRESSIONS)
        {
            return;
        }

        if (permutation.Count == _parameterTypeCombinations.Count)
        {
            var permutationCopy = permutation.Reverse().ToArray();
            generatedExpressions.Add(new GeneratedExpression(_expressionTemplate, permutationCopy));
            return;
        }

        var parameterTypes = _parameterTypeCombinations[permutation.Count];
        foreach (var parameterType in parameterTypes)
        {
            // Avoid recursion if no elements can be added.
            if (generatedExpressions.Count >= MAX_EXPRESSIONS)
            {
                return;
            }
            permutation.Push(parameterType);
            GeneratePermutations(generatedExpressions, permutation);
            permutation.Pop();
        }
    }
}
