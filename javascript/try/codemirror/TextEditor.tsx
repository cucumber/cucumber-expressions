import { defaultKeymap } from '@codemirror/commands'
import { EditorState } from '@codemirror/state'
import { EditorView, keymap } from '@codemirror/view'
import React, { useEffect, useRef, useState } from 'react'

// https://discuss.codemirror.net/t/react-hooks/3409
// https://codemirror.net/6/examples/styling/
import { Argument } from '../../src'
import { setArgs } from './args.js'
import { theme } from './theme.js'

// This code is inspired from
// https://github.com/codemirror/lint/blob/main/src/lint.ts

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
      view.dispatch(setArgs(state, args || []))
    }
  }, [state, view, args])

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
      extensions: [theme, keymap.of(defaultKeymap), singleLineFilter, updateStateFilter],
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
