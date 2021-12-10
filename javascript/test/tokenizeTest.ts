import assert from 'assert'

import { Token, TokenType } from '../src/Ast.js'

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
    return this.previousTokenType === TokenType.text && this.tokenType !== TokenType.text
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
  if (input.length == 0) {
    return []
  }

  //  "hello world" --> 3 tokens
  //  "hello  world"  --> 4 tokens
  //       ^
  // firstIndex
  // curentType

  let currentIndex = 0
  let cursor = new Cursor(input, currentIndex)

  while (currentIndex < input.length) {
    cursor = new Cursor(input, currentIndex)

    if (cursor.isAtStartOfWord) {
      const word = input.slice(cursor.currentIndex, cursor.endOfCurrentWord)
      tokens.push(new Token(TokenType.text, word, cursor.currentIndex, cursor.endOfCurrentWord))
      currentIndex = cursor.endOfCurrentWord
    }

    if (cursor.isAtEndOfSingleCharacter) {
      tokens.push(
        new Token(
          cursor.tokenType,
          cursor.input[cursor.currentIndex],
          cursor.currentIndex,
          cursor.currentIndex + 1
        )
      )
      currentIndex++
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
