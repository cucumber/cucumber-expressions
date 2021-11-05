using System;
using System.Collections.Generic;
using System.Linq;

namespace CucumberExpressions;


public class CombinatorialGeneratedExpressionFactory {
    // 256 generated expressions ought to be enough for anybody
    private const int MAX_EXPRESSIONS = 256;
    private readonly String expressionTemplate;
    private readonly List<List<IParameterType>> parameterTypeCombinations;

    public CombinatorialGeneratedExpressionFactory(
            String expressionTemplate,
            List<List<IParameterType>> parameterTypeCombinations) {

        this.expressionTemplate = expressionTemplate;
        this.parameterTypeCombinations = parameterTypeCombinations;
    }

    public List<GeneratedExpression> generateExpressions() {
        var generatedExpressions = new List<GeneratedExpression>();
        var permutation = new Stack<IParameterType>(parameterTypeCombinations.Count);
        generatePermutations(generatedExpressions, permutation);
        return generatedExpressions;
    }

    private void generatePermutations(
            List<GeneratedExpression> generatedExpressions,
            Stack<IParameterType> permutation
    ) {
        if (generatedExpressions.Count >= MAX_EXPRESSIONS) {
            return;
        }

        if (permutation.Count == parameterTypeCombinations.Count) {
            var permutationCopy = new List<IParameterType>(permutation.Reverse());
            generatedExpressions.Add(new GeneratedExpression(expressionTemplate, permutationCopy));
            return;
        }

        var parameterTypes = parameterTypeCombinations[permutation.Count];
        foreach (var parameterType in parameterTypes) {
            // Avoid recursion if no elements can be added.
            if (generatedExpressions.Count >= MAX_EXPRESSIONS) {
                return;
            }
            permutation.Push(parameterType);
            generatePermutations(generatedExpressions, permutation);
            permutation.Pop();
        }
    }
}
