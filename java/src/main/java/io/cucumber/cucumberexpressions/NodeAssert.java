package io.cucumber.cucumberexpressions;

import java.util.function.Function;

import static io.cucumber.cucumberexpressions.Ast.Node.Type.*;

public class NodeAssert {

    public void assertNotEmpty(Ast.Node node,
                                Function<Ast.Node, CucumberExpressionException> createNodeWasNotEmptyException) {
        node.nodes()
                .stream()
                .filter(astNode -> TEXT_NODE.equals(astNode.type()))
                .findFirst()
                .orElseThrow(() -> createNodeWasNotEmptyException.apply(node));
    }

    public void assertNoParameters(Ast.Node node,
                                    Function<Ast.Node, CucumberExpressionException> createNodeContainedAParameterException) {
        assertNoNodeOfType(PARAMETER_NODE, node, createNodeContainedAParameterException);
    }

    public void assertNoOptionals(Ast.Node node,
                                   Function<Ast.Node, CucumberExpressionException> createNodeContainedAnOptionalException) {
        assertNoNodeOfType(OPTIONAL_NODE, node, createNodeContainedAnOptionalException);
    }

    public void assertNoNodeOfType(Ast.Node.Type nodeType, Ast.Node node,
                                    Function<Ast.Node, CucumberExpressionException> createException) {
        node.nodes()
                .stream()
                .filter(astNode -> nodeType.equals(astNode.type()))
                .map(createException)
                .findFirst()
                .ifPresent(exception -> {
                    throw exception;
                });
    }
}
