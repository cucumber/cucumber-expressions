import { EditorState, StateEffect, StateField, TransactionSpec } from '@codemirror/state'
import { Decoration, DecorationSet, EditorView, MatchDecorator } from '@codemirror/view'

import { Argument } from '../../src'

const setArgsEffect = StateEffect.define<readonly Argument[]>()

class ArgsState {
  constructor(readonly decorations: DecorationSet, readonly args: readonly Argument[]) {}

  static init(args: readonly Argument[]) {
    const decorations = Decoration.set(
      args.map((arg: Argument) =>
        Decoration.mark({
          attributes: { class: 'cm-param' },
          arg,
        }).range(arg.group.start || 0, arg.group.end || 0)
      ),
      true
    )
    return new ArgsState(decorations, args)
  }
}

const argsState = StateField.define<ArgsState>({
  create: () => new ArgsState(Decoration.none, []),
  update: (value, tr) => {
    return tr.docChanged ? new ArgsState(value.decorations.map(tr.changes), []) : value
  },
  provide: (f) => [EditorView.decorations.from(f, (s) => s.decorations)],
})

export function setArgs(state: EditorState, args: readonly Argument[]): TransactionSpec {
  return {
    effects: [
      setArgsEffect.of(args),
      StateEffect.appendConfig.of([argsState.init(() => ArgsState.init(args))]),
    ],
  }
}
