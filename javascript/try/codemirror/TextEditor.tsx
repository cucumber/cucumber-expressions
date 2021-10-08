import { EditorSelection, EditorState } from '@codemirror/state'
import React from 'react'

import { Argument } from '../../src'
import { CodeMirrorElement, useEditorView, useExtension } from './codemirror.js'
import highlightArgsExtension from './highlightArgsExtension.js'
import setLinesExtension from './setStateExtension.js'
import singleLineExtension from './singleLineExtension.js'
import { baseTheme, matchTheme, noMatchTheme } from './theme.js'

export const TextEditor: React.FunctionComponent<{
  value: string
  setValue: (newValue: string) => void
  autoFocus: boolean
  args: readonly Argument[] | null | undefined
}> = ({ value, setValue, autoFocus, args }) => {
  const view = useEditorView(() =>
    EditorState.create({
      doc: value,
      selection: EditorSelection.single(value.length),
    })
  )
  useExtension(view, () => baseTheme, [])
  useExtension(view, () => (Array.isArray(args) ? matchTheme : noMatchTheme), [args])
  useExtension(view, () => singleLineExtension, [])
  useExtension(view, () => setLinesExtension((lines) => setValue(lines[0])), [])
  useExtension(view, () => highlightArgsExtension(args), [args])

  return <CodeMirrorElement autoFocus={autoFocus} view={view} />
}
