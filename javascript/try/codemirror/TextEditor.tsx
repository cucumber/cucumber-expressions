import { EditorState } from '@codemirror/state'
import React from 'react'

import { Argument } from '../../src'
import { CodeMirrorElement, useEditorView, useExtension } from './codemirror'
import highlightArgsExtension from './highlightArgsExtension'
import setLinesExtension from './setStateExtension'
import singleLineExtension from './singleLineExtension'
import { theme } from './theme'

export const TextEditor: React.FunctionComponent<{
  value: string
  setValue: (newValue: string) => void
  args: readonly Argument[] | null | undefined
}> = ({ value, setValue, args }) => {
  const view = useEditorView(() => EditorState.create({ doc: value }))
  useExtension(view, () => theme, [])
  useExtension(view, () => singleLineExtension, [])
  useExtension(view, () => setLinesExtension((lines) => setValue(lines[0])), [])
  useExtension(view, () => highlightArgsExtension(args), [args])

  return <CodeMirrorElement autoFocus={true} view={view} />
}
