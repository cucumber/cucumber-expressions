import { StateField } from '@codemirror/state'
import { Decoration, DecorationSet, EditorView, ViewPlugin } from '@codemirror/view'

import { Argument } from '../../src'

const argsFiels = StateField.define<readonly Argument[]>({})

function createDecorations(view: EditorView): DecorationSet {
  view.state.field(argsFiels)
  return Decoration.none
}

const plugin = ViewPlugin.define(
  (view) => ({
    decorations: createDecorations(view),
    update(u) {
      this.decorations = createDecorations(u.view)
    },
  }),
  {
    decorations: (v) => v.decorations,
  }
)
