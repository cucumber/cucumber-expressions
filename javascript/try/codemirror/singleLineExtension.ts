// https://discuss.codemirror.net/t/codemirror-6-single-line-and-or-avoid-carriage-return/2979/3
import { EditorState } from '@codemirror/state'

export default EditorState.transactionFilter.of((tr) => (tr.newDoc.lines > 1 ? [] : tr))
