import assert from 'assert'
import { cursorTo } from 'readline'

import { Token, TokenType } from '../src/Ast.js'

type EmitsTokens = (token: Token) => void

class ReadingSingleCharacter {
  constructor(
    private readonly tokenType: TokenType,
    private readonly input: string,
    private readonly currentIndex: number
  ) {}

  emit(fn: EmitsTokens) {
    fn(
      new Token(
        this.tokenType,
        this.input[this.currentIndex],
        this.currentIndex,
        this.currentIndex + 1
      )
    )
  }
}

class Cursor {
  constructor(public readonly input: string, public readonly currentIndex: number) {}

  get tokenType(): TokenType {
    return Token.typeOf(this.input[this.currentIndex])
  }

  get previousTokenType(): TokenType | undefined {
    if (this.currentIndex === 0) {
      return undefined
    }
    return Token.typeOf(this.input[this.currentIndex - 1])
  }

  get isAtStartOfWord(): boolean {
    return this.previousTokenType !== TokenType.text && this.tokenType === TokenType.text
  }

  get isAtEndOfWord(): boolean {
    return (
      this.previousTokenType !== undefined &&
      this.previousTokenType !== this.tokenType &&
      this.tokenType !== TokenType.text
    )
  }
}

const tokenize: (input: string) => Token[] = (input) => {
  const tokens: Array<Token> = []

  //  "hello world" --> 3 tokens
  //  "hello  world"  --> 4 tokens
  //       ^
  // firstIndex
  // curentType

  let startOfWord = -1
  let currentIndex = 0
  let tokenType: TokenType | undefined = undefined

  for (currentIndex; currentIndex < input.length; currentIndex++) {
    const cursor = new Cursor(input, currentIndex)
    tokenType = cursor.tokenType

    // moving into a string?
    if (cursor.isAtStartOfWord) {
      startOfWord = currentIndex
    }

    if (cursor.isAtEndOfWord) {
      const subString = input.slice(startOfWord, currentIndex)
      tokens.push(new Token(TokenType.text, subString, startOfWord, startOfWord + subString.length))
    }

    if (tokenType !== TokenType.text) {
      const state = new ReadingSingleCharacter(tokenType, input, currentIndex)
      state.emit((token) => tokens.push(token))
    }
  }

  //  "hello world" --> 3 tokens
  //  "hello"  --> 4 tokens
  //       ^

  currentIndex++
  if (tokenType === TokenType.text) {
    const subString = input.slice(startOfWord, currentIndex)
    tokens.push(new Token(TokenType.text, subString, startOfWord, startOfWord + subString.length))
  }

  return tokens
}

describe(tokenize.name, () => {
  it('empty string', () => {
    const result = tokenize('')
    assert.deepEqual(result, [])
  })

  it('single-character word', () => {
    const result = tokenize('a')
    assert.deepEqual(result, [new Token(TokenType.text, 'a', 0, 1)])
  })

  it('two-character word', () => {
    const result = tokenize('ab')
    assert.deepEqual(result, [new Token(TokenType.text, 'ab', 0, 2)])
  })

  it('a space', () => {
    const result = tokenize(' ')
    assert.deepEqual(result, [new Token(TokenType.whiteSpace, ' ', 0, 1)])
  })

  it('two consecutive spaces', () => {
    const result = tokenize('  ')
    assert.deepEqual(result, [
      new Token(TokenType.whiteSpace, ' ', 0, 1),
      new Token(TokenType.whiteSpace, ' ', 1, 2),
    ])
  })

  it('a single-character word followed by a space', () => {
    const result = tokenize('a ')
    assert.deepEqual(result, [
      new Token(TokenType.text, 'a', 0, 1),
      new Token(TokenType.whiteSpace, ' ', 1, 2),
    ])
  })

  it('a space followed by a single-character word', () => {
    const result = tokenize(' b')
    assert.deepEqual(result, [
      new Token(TokenType.whiteSpace, ' ', 0, 1),
      new Token(TokenType.text, 'b', 1, 2),
    ])
  })

  it('a word', () => {
    const result = tokenize('abc')
    assert.deepEqual(result, [new Token(TokenType.text, 'abc', 0, 3)])
  })

  it('a word followed by a space', () => {
    const result = tokenize('ab ')
    assert.deepEqual(result, [
      new Token(TokenType.text, 'ab', 0, 2),
      new Token(TokenType.whiteSpace, ' ', 2, 3),
    ])
  })

  it('word - space - word', () => {
    const result = tokenize('a c')
    assert.deepEqual(result, [
      new Token(TokenType.text, 'a', 0, 1),
      new Token(TokenType.whiteSpace, ' ', 1, 2),
      new Token(TokenType.text, 'c', 2, 3),
    ])
  })

  it('space - word', () => {
    const result = tokenize(' bc')
    assert.deepEqual(result, [
      new Token(TokenType.whiteSpace, ' ', 0, 1),
      new Token(TokenType.text, 'bc', 1, 3),
    ])
  })

  it('handles a string with unnicode / emojis in it')
})
