import { EditorSelection, EditorState } from '@codemirror/state'
import React from 'react'

import { CodeMirrorElement, useEditorView, useExtension } from './codemirror.js'
import setLinesExtension from './setStateExtension.js'
import singleLineExtension from './singleLineExtension.js'
import { baseTheme } from './theme.js'

export const ExpressionEditor: React.FunctionComponent<{
  value: string
  setValue: (newValue: string) => void
  autoFocus: boolean
}> = ({ value, setValue, autoFocus }) => {
  const view = useEditorView(() =>
    EditorState.create({ doc: value, selection: EditorSelection.single(value.length) })
  )
  useExtension(view, () => baseTheme, [])
  useExtension(view, () => singleLineExtension, [])
  useExtension(view, () => setLinesExtension((lines) => setValue(lines[0])), [])

  return <CodeMirrorElement autoFocus={autoFocus} view={view} />
}
