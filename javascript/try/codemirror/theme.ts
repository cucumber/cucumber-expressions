import { EditorView } from '@codemirror/view'

export const theme = EditorView.theme(
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
    '.cm-arg-match': {
      backgroundColor: 'rgba(209, 250, 229)',
    },
    '.cm-param': {
      background: '#ffc010',
    },
    '.cm-no-arg-match': {
      backgroundColor: 'rgba(254, 226, 226)',
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
