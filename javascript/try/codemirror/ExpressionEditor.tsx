import { EditorSelection, EditorState } from '@codemirror/state'
import React from 'react'

import { CodeMirrorElement, useEditorView, useExtension } from './codemirror.js'
import setLinesExtension from './setStateExtension.js'
import singleLineExtension from './singleLineExtension.js'
import { baseTheme, errorTheme, okTheme } from './theme.js'

export const ExpressionEditor: React.FunctionComponent<{
  value: string
  setValue: (newValue: string) => void
  error: boolean
  autoFocus: boolean
}> = ({ value, setValue, error, autoFocus }) => {
  const view = useEditorView(() =>
    EditorState.create({ doc: value, selection: EditorSelection.single(value.length) })
  )
  useExtension(view, () => baseTheme, [])
  useExtension(view, () => (error ? errorTheme : okTheme), [error])
  useExtension(view, () => singleLineExtension, [])
  useExtension(view, () => setLinesExtension((lines) => setValue(lines[0])), [])

  return <CodeMirrorElement autoFocus={autoFocus} view={view} />
}
