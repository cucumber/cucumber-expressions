import { EditorState, StateField } from '@codemirror/state'
import { showTooltip, Tooltip } from '@codemirror/view'

import { Argument } from '../../src'

export default function argTooltipExtension(args: readonly Argument[] | undefined | null) {
  return StateField.define<readonly Tooltip[]>({
    create: getCursorTooltips,

    update(tooltips, tr) {
      if (!tr.docChanged && !tr.selection) return tooltips
      return getCursorTooltips(tr.state)
    },

    provide: (f) => showTooltip.computeN([f], (state) => state.field(f)),
  })

  function getCursorTooltips(state: EditorState): readonly Tooltip[] {
    const cursorRange = state.selection.ranges.filter((range) => range.empty)
    if (cursorRange.length !== 1) return []
    const range = cursorRange[0]
    const line = state.doc.lineAt(range.head)
    const column = range.head - line.from
    const arg = (args || []).find(
      (arg) => (arg.group.start || -1) <= column && column < (arg.group.end || -1)
    )
    if (!arg) return []

    const type = arg.parameterType.name
    const value = JSON.stringify(arg.getValue(null))
    const toolTip: Tooltip = {
      pos: range.head,
      above: true,
      strictSide: true,
      create: () => {
        const dom = document.createElement('div')
        dom.classList.add('cm-cursor-tooltip')
        dom.textContent = `${type}: ${value}`
        return { dom }
      },
    }
    return [toolTip]
  }
}
