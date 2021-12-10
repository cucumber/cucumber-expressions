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

  get tokenType(): TokenType | undefined {
    if (this.input.length === 0) return undefined
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
      (this.previousTokenType === TokenType.text && this.tokenType !== TokenType.text) ||
      (this.currentIndex == this.input.length && this.previousTokenType == TokenType.text)
    )
  }

  get atEndOfInput(): boolean {
    return this.currentIndex == this.input.length
  }

  get endOfCurrentWord(): number {
    let cursor = new Cursor(this.input, this.currentIndex)
    while (!cursor.atEndOfInput) {
      cursor = new Cursor(this.input, cursor.currentIndex + 1)
      if (cursor.isAtEndOfWord) {
        return cursor.currentIndex
      }
    }
    return this.input.length
  }

  get isAtEndOfSingleCharacter() {
    return this.tokenType !== TokenType.text && this.tokenType !== undefined
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
  let endOfWord = -1
  let currentIndex = 0

  for (currentIndex; currentIndex < input.length + 1; currentIndex++) {
    const cursor = new Cursor(input, currentIndex)

    // moving into a string?
    if (cursor.isAtStartOfWord) {
      startOfWord = currentIndex
      endOfWord = cursor.endOfCurrentWord
    }

    if (cursor.isAtEndOfWord) {
      const subString = input.slice(startOfWord, currentIndex)
      assert.equal(currentIndex, endOfWord)
      tokens.push(new Token(TokenType.text, subString, startOfWord, startOfWord + subString.length))
    }

    if (cursor.isAtEndOfSingleCharacter && cursor.tokenType) {
      const state = new ReadingSingleCharacter(cursor.tokenType, input, currentIndex)
      state.emit((token) => tokens.push(token))
    }
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
