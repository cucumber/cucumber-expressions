const escapeCharacter = '\\'
const alternationCharacter = '/'
const beginParameterCharacter = '{'
const endParameterCharacter = '}'
const beginOptionalCharacter = '('
const endOptionalCharacter = ')'

export function symbolOf(token: TokenType): string {
  switch (token) {
    case TokenType.beginOptional:
      return beginOptionalCharacter
    case TokenType.endOptional:
      return endOptionalCharacter
    case TokenType.beginParameter:
      return beginParameterCharacter
    case TokenType.endParameter:
      return endParameterCharacter
    case TokenType.alternation:
      return alternationCharacter
  }
  return ''
}

export function purposeOf(token: TokenType): string {
  switch (token) {
    case TokenType.beginOptional:
    case TokenType.endOptional:
      return 'optional text'
    case TokenType.beginParameter:
    case TokenType.endParameter:
      return 'a parameter'
    case TokenType.alternation:
      return 'alternation'
  }
  return ''
}

export interface Located {
  readonly start: number
  readonly end: number
}

export class Node implements Located {
  constructor(
    public readonly type: NodeType,
    public readonly nodes: readonly Node[] | undefined,
    private readonly token: string | undefined,
    public readonly start: number,
    public readonly end: number
  ) {
    if (nodes === undefined && token === undefined) {
      throw new Error('Either nodes or token must be defined')
    }
  }

  text(): string {
    if (this.nodes && this.nodes.length > 0) {
      return this.nodes.map((value) => value.text()).join('')
    }
    return this.token || ''
  }
}

export enum NodeType {
  text = 'TEXT_NODE',
  optional = 'OPTIONAL_NODE',
  alternation = 'ALTERNATION_NODE',
  alternative = 'ALTERNATIVE_NODE',
  parameter = 'PARAMETER_NODE',
  expression = 'EXPRESSION_NODE',
}

export class Token implements Located {
  readonly type: TokenType
  readonly text: string
  readonly start: number
  readonly end: number

  constructor(type: TokenType, text: string, start: number, end: number) {
    this.type = type
    this.text = text
    this.start = start
    this.end = end
  }

  static isEscapeCharacter(codePoint: string): boolean {
    return codePoint == escapeCharacter
  }

  static canEscape(codePoint: string): boolean {
    if (codePoint == ' ') {
      // TODO: Unicode whitespace?
      return true
    }
    switch (codePoint) {
      case escapeCharacter:
        return true
      case alternationCharacter:
        return true
      case beginParameterCharacter:
        return true
      case endParameterCharacter:
        return true
      case beginOptionalCharacter:
        return true
      case endOptionalCharacter:
        return true
    }
    return false
  }

  static typeOf(codePoint: string): TokenType {
    if (codePoint == ' ') {
      // TODO: Unicode whitespace?
      return TokenType.whiteSpace
    }
    switch (codePoint) {
      case alternationCharacter:
        return TokenType.alternation
      case beginParameterCharacter:
        return TokenType.beginParameter
      case endParameterCharacter:
        return TokenType.endParameter
      case beginOptionalCharacter:
        return TokenType.beginOptional
      case endOptionalCharacter:
        return TokenType.endOptional
    }
    return TokenType.text
  }
}

export enum TokenType {
  startOfLine = 'START_OF_LINE',
  endOfLine = 'END_OF_LINE',
  whiteSpace = 'WHITE_SPACE',
  beginOptional = 'BEGIN_OPTIONAL',
  endOptional = 'END_OPTIONAL',
  beginParameter = 'BEGIN_PARAMETER',
  endParameter = 'END_PARAMETER',
  alternation = 'ALTERNATION',
  text = 'TEXT',
}
