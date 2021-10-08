import { EditorView } from '@codemirror/view'

export const baseTheme = EditorView.theme(
  {
    '&': {
      border: 'solid',
      borderWidth: '1px',
      borderColor: '#6b7280', // text-gray-700
      padding: '6px',
      fontSize: '1rem',
    },
    '.cm-arg': {
      background: '#ffc010',
    },
    '&.cm-focused': {
      outline: '2px solid #2563eb',
    },
    '&.cm-focused .cm-selectionBackground, ::selection': {
      outline: '2px solid #2563eb',
    },
  },
  { dark: false }
)

export const matchTheme = EditorView.theme({
  '&': {
    backgroundColor: 'rgba(209, 250, 229)',
  },
})

export const noMatchTheme = EditorView.theme({
  '&': {
    backgroundColor: 'rgba(254, 226, 226)',
  },
})
