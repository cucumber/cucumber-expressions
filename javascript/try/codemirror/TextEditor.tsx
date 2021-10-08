import { EditorSelection, EditorState } from '@codemirror/state'
import React from 'react'

import { Argument } from '../../src'
import argTooltipExtension from './argTooltipExtension.js'
import { CodeMirrorElement, useEditorView, useExtension } from './codemirror.js'
import highlightArgsExtension from './highlightArgsExtension.js'
import setLinesExtension from './setStateExtension.js'
import singleLineExtension from './singleLineExtension.js'
import { baseTheme, cursorTooltipBaseTheme, errorTheme, okTheme } from './theme.js'

export const TextEditor: React.FunctionComponent<{
  value: string
  setValue: (newValue: string) => void
  args: readonly Argument[] | null | undefined
  autoFocus: boolean
}> = ({ value, setValue, args, autoFocus }) => {
  const view = useEditorView(() =>
    EditorState.create({
      doc: value,
      selection: EditorSelection.single(value.length),
    })
  )
  useExtension(view, () => baseTheme, [])
  useExtension(view, () => (Array.isArray(args) ? okTheme : errorTheme), [args])
  useExtension(view, () => singleLineExtension, [])
  useExtension(view, () => setLinesExtension((lines) => setValue(lines[0])), [])
  useExtension(view, () => highlightArgsExtension(args), [args])
  useExtension(view, () => [argTooltipExtension(args), cursorTooltipBaseTheme], [args])

  return <CodeMirrorElement autoFocus={autoFocus} view={view} />
}
