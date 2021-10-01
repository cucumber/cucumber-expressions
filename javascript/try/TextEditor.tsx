import { defaultKeymap } from '@codemirror/commands'
import { EditorState, StateEffect, StateField, TransactionSpec } from '@codemirror/state'
import { Decoration, DecorationSet, EditorView, keymap } from '@codemirror/view'
import React, { useEffect, useRef, useState } from 'react'

import { Argument } from '../src'

const setArgsEffect = StateEffect.define<readonly Argument[]>()

class ArgsState {
  constructor(readonly decorations: DecorationSet) {}

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
    return new ArgsState(decorations)
  }
}

const argsState = StateField.define<ArgsState>({
  create() {
    return new ArgsState(Decoration.none)
  },
  update(value, tr) {
    if (tr.docChanged) {
      const mapped = value.decorations.map(tr.changes)
      value = new ArgsState(mapped)
    }
    return value
  },
  provide: (f) => [EditorView.decorations.from(f, (s) => s.decorations)],
})

function maybeEnableArgs(
  state: EditorState,
  effects: readonly StateEffect<unknown>[],
  getState: () => ArgsState
) {
  return state.field(argsState, false)
    ? effects
    : effects.concat(StateEffect.appendConfig.of([argsState.init(getState)]))
}

function setArguments(state: EditorState, args: readonly Argument[]): TransactionSpec {
  return {
    effects: maybeEnableArgs(state, [setArgsEffect.of(args)], () => ArgsState.init(args)),
  }
}

export const TextEditor: React.FunctionComponent<{
  value: string
  setValue: (newValue: string) => void
  args: readonly Argument[] | null | undefined
}> = ({ value, setValue, args }) => {
  const editor = useRef<HTMLDivElement>(null)
  const [state, setState] = useState<EditorState>()
  const [view, setView] = useState<EditorView>()

  useEffect(() => {
    if (view && state) {
      view.dispatch(setArguments(state, args || []))
    }
  }, [state, view, args])

  // https://discuss.codemirror.net/t/react-hooks/3409
  // https://github.com/FurqanSoftware/codemirror-languageserver
  // https://discuss.codemirror.net/t/what-is-the-correct-way-to-set-decorations-asynchronously/3266

  useEffect(() => {
    // https://discuss.codemirror.net/t/codemirror-6-single-line-and-or-avoid-carriage-return/2979/3
    const singleLineFilter = EditorState.transactionFilter.of((tr) =>
      tr.newDoc.lines > 1 ? [] : tr
    )
    const updateStateFilter = EditorState.transactionFilter.of((tr) => {
      const newValue = tr.newDoc.toJSON()[0]
      setValue(newValue)
      return tr
    })

    const state = EditorState.create({
      doc: value,
      extensions: [keymap.of(defaultKeymap), singleLineFilter, updateStateFilter],
    })
    setState(state)

    const view = new EditorView({
      state,
      parent: editor.current || undefined,
    })
    setView(view)

    return () => view.destroy()
  }, [])

  return <div ref={editor} />
}
