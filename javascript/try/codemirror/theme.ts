import { EditorView } from '@codemirror/view'

/*
IBM palette for colour-blind people
https://davidmathlogic.com/colorblind/#%23648FFF-%23785EF0-%23DC267F-%23FE6100-%23FFB000
*/

export const baseTheme = EditorView.theme({
  '&': {
    border: 'solid',
    borderWidth: '1px',
    borderColor: '#000000', // text-gray-700
    padding: '6px',
    fontSize: '1rem',
    color: '#ffffff',
  },
  '.cm-content': {
    caretColor: '#ffffff',
  },
  '&.cm-editor.cm-focused': {
    outline: '3px solid #000000',
  },
  '&.cm-focused .cm-selectionBackground, ::selection': {
    backgroundColor: '#785EF0',
  },
  '.cm-arg': {
    backgroundColor: '#FE6100',
  },
})

export const okTheme = EditorView.theme({
  '&': {
    backgroundColor: '#648FFF',
  },
})

export const errorTheme = EditorView.theme({
  '&': {
    backgroundColor: '#DC267F',
  },
})

export const cursorTooltipBaseTheme = EditorView.baseTheme({
  '.cm-tooltip.cm-cursor-tooltip': {
    backgroundColor: '#000000',
    color: '#ffffff',
    transform: 'translate(-50%, -7px)',
    border: 'none',
    padding: '2px 7px',
    borderRadius: '10px',
    '&:before': {
      position: 'absolute',
      content: '""',
      left: '50%',
      marginLeft: '-5px',
      bottom: '-5px',
      borderLeft: '5px solid transparent',
      borderRight: '5px solid transparent',
      borderTop: '5px solid #000000',
    },
  },
})
