import { EditorView } from '@codemirror/view'

/**
 * This extension invokes a callback when the editor contents change
 * @param setLines
 */
export default function setLinesExtension(setLines: (newLines: readonly string[]) => void) {
  return EditorView.updateListener.of((update) => {
    if (update.docChanged) {
      setLines(update.state.doc.toJSON())
    }
  })
}
