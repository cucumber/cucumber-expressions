// https://discuss.codemirror.net/t/codemirror-6-single-line-and-or-avoid-carriage-return/2979/3
import { EditorState } from '@codemirror/state'

/**
 * This extension makes the editor behave like a single-line input field
 */
export default EditorState.transactionFilter.of((tr) => (tr.newDoc.lines > 1 ? [] : tr))
