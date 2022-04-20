import { Node, NodeType } from './Ast.js'
import CucumberExpressionError from './CucumberExpressionError.js'
import {
  createAlternativeMayNotBeEmpty,
  createAlternativeMayNotExclusivelyContainOptionals,
  createOptionalIsNotAllowedInOptional,
  createOptionalMayNotBeEmpty,
  createParameterIsNotAllowedInOptional,
  createUndefinedParameterType,
} from './Errors.js'
import ParameterType from './ParameterType.js'
import ParameterTypeRegistry from './ParameterTypeRegistry.js'

export default abstract class Compiler<T> {
  constructor(
    private readonly expression: string,
    private readonly parameterTypeRegistry: ParameterTypeRegistry
  ) {}

  protected abstract produceText(expression: string): T
  protected abstract produceOptional(segments: T[]): T
  protected abstract produceAlternation(segments: T[]): T
  protected abstract produceAlternative(segments: T[]): T
  protected abstract produceParameter(parameterType: ParameterType<unknown>): T
  protected abstract produceExpression(segments: T[]): T

  public compile(node: Node): T {
    switch (node.type) {
      case NodeType.text:
        return this.produceText(node.text())
      case NodeType.optional:
        return this.compileOptional(node)
      case NodeType.alternation:
        return this.compileAlternation(node)
      case NodeType.alternative:
        return this.compileAlternative(node)
      case NodeType.parameter:
        return this.compileParameter(node)
      case NodeType.expression:
        return this.compileExpression(node)
      default:
        // Can't happen as long as the switch case is exhaustive
        throw new Error(node.type)
    }
  }

  private compileOptional(node: Node): T {
    this.assertNoParameters(node, (astNode) =>
      createParameterIsNotAllowedInOptional(astNode, this.expression)
    )
    this.assertNoOptionals(node, (astNode) =>
      createOptionalIsNotAllowedInOptional(astNode, this.expression)
    )
    this.assertNotEmpty(node, (astNode) => createOptionalMayNotBeEmpty(astNode, this.expression))

    const segments = (node.nodes || []).map((node) => this.compile(node))
    return this.produceOptional(segments)
  }

  private compileAlternation(node: Node) {
    // Make sure the alternative parts aren't empty and don't contain parameter types
    for (const alternative of node.nodes || []) {
      if (!alternative.nodes || alternative.nodes.length == 0) {
        throw createAlternativeMayNotBeEmpty(alternative, this.expression)
      }
      this.assertNotEmpty(alternative, (astNode) =>
        createAlternativeMayNotExclusivelyContainOptionals(astNode, this.expression)
      )
    }
    const segments = (node.nodes || []).map((node) => this.compile(node))
    return this.produceAlternation(segments)
  }

  private compileAlternative(node: Node) {
    const segments = (node.nodes || []).map((lastNode) => this.compile(lastNode))
    return this.produceAlternative(segments)
  }

  private compileParameter(node: Node) {
    const name = node.text()
    const parameterType = this.parameterTypeRegistry.lookupByTypeName(name)
    if (!parameterType) {
      throw createUndefinedParameterType(node, this.expression, name)
    }
    return this.produceParameter(parameterType)
  }

  private compileExpression(node: Node) {
    const segments = (node.nodes || []).map((node) => this.compile(node))
    return this.produceExpression(segments)
  }

  private assertNotEmpty(
    node: Node,
    createNodeWasNotEmptyException: (astNode: Node) => CucumberExpressionError
  ) {
    const textNodes = (node.nodes || []).filter((astNode) => NodeType.text == astNode.type)

    if (textNodes.length == 0) {
      throw createNodeWasNotEmptyException(node)
    }
  }

  private assertNoParameters(
    node: Node,
    createNodeContainedAParameterError: (astNode: Node) => CucumberExpressionError
  ) {
    const parameterNodes = (node.nodes || []).filter(
      (astNode) => NodeType.parameter == astNode.type
    )
    if (parameterNodes.length > 0) {
      throw createNodeContainedAParameterError(parameterNodes[0])
    }
  }

  private assertNoOptionals(
    node: Node,
    createNodeContainedAnOptionalError: (astNode: Node) => CucumberExpressionError
  ) {
    const parameterNodes = (node.nodes || []).filter((astNode) => NodeType.optional == astNode.type)
    if (parameterNodes.length > 0) {
      throw createNodeContainedAnOptionalError(parameterNodes[0])
    }
  }
}
