import { Decoration, DecorationSet, ViewPlugin } from '@codemirror/view'

import { Argument } from '../../src'

export default function highlightArgsExtension(args: readonly Argument[] | null | undefined) {
  return ViewPlugin.define(
    () => ({
      decorations: createArgDecorations(args),
      update(update) {
        if (update.docChanged || update.viewportChanged) {
          this.decorations = createArgDecorations(args)
        }
      },
    }),
    {
      decorations: (v) => v.decorations,
    }
  )
}

function createArgDecorations(args: readonly Argument[] | null | undefined): DecorationSet {
  return Decoration.set(
    (args || []).map((arg: Argument) =>
      Decoration.mark({
        attributes: { class: 'cm-arg' },
        arg,
      }).range(arg.group.start || 0, arg.group.end || 0)
    ),
    true
  )
}
