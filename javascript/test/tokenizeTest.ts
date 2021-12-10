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

  get atStartOfWord(): boolean {
    return this.previousTokenType !== TokenType.text && this.tokenType === TokenType.text
  }

  get atEndOfWord(): boolean {
    return this.previousTokenType === TokenType.text && this.tokenType !== TokenType.text
  }

  get atEndOfInput(): boolean {
    return this.currentIndex == this.input.length
  }

  get endOfCurrentWord(): number {
    let cursor = new Cursor(this.input, this.currentIndex)
    while (!cursor.atEndOfInput) {
      cursor = new Cursor(this.input, cursor.currentIndex + 1)
      if (cursor.atEndOfWord) {
        return cursor.currentIndex
      }
    }
    return this.input.length
  }

  scan(emit: (token: Token) => void): Cursor {
    if (this.atStartOfWord) {
      const word = this.input.slice(this.currentIndex, this.endOfCurrentWord)
      emit(new Token(TokenType.text, word, this.currentIndex, this.endOfCurrentWord))
      return new Cursor(this.input, this.endOfCurrentWord)
    }

    emit(
      new Token(
        this.tokenType,
        this.input[this.currentIndex],
        this.currentIndex,
        this.currentIndex + 1
      )
    )
    return new Cursor(this.input, this.currentIndex + 1)
  }
}

const tokenize: (input: string) => Token[] = (input) => {
  const tokens: Array<Token> = []

  if (input.length == 0) {
    return []
  }

  let cursor = new Cursor(input, 0)
  while (!cursor.atEndOfInput) {
    cursor = cursor.scan((token) => tokens.push(token))
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
