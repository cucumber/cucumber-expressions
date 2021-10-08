import { EditorView } from '@codemirror/view'

export default function setLinesExtension(setLines: (newLines: readonly string[]) => void) {
  return EditorView.updateListener.of((update) => {
    if (update.docChanged) {
      setLines(update.state.doc.toJSON())
    }
  })
}
