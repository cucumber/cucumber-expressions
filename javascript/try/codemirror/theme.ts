import { EditorView } from '@codemirror/view'

export const baseTheme = EditorView.theme(
  {
    '&': {
      // color: 'white',
      // backgroundColor: '#034',
      border: 'solid',
      borderWidth: '1px',
      borderColor: '#6b7280', // text-gray-700
      padding: '6px',
      fontSize: '1rem',
    },
    '.cm-arg': {
      background: '#ffc010',
    },
    '.cm-content': {
      // caretColor: '#0e9',
    },
    '&.cm-focused .cm-cursor': {
      // borderLeftColor: '#0e9',
      outline: 'none',
    },
    '&.cm-focused .cm-selectionBackground, ::selection': {
      // backgroundColor: '#074'
    },
    '.cm-gutters': {
      // backgroundColor: '#045',
      // color: '#ddd',
      border: 'none',
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
