// https://discuss.codemirror.net/t/react-hooks/3409
// https://gist.github.com/s-cork/e7104bace090702f6acbc3004228f2cb
import {
  Compartment,
  EditorState,
  EditorStateConfig,
  Extension,
  StateEffect,
} from '@codemirror/state'
import { EditorView } from '@codemirror/view'
import React, { useCallback, useEffect, useLayoutEffect, useMemo, useState } from 'react'

/** creates an editor view from an initial state - destroys the view on cleanup */
export function useEditorView(
  initState: (() => EditorStateConfig) | EditorStateConfig = {}
): EditorView {
  const view = useMemo(
    () =>
      new EditorView({
        state: EditorState.create(typeof initState === 'function' ? initState() : initState),
      }),
    []
  )
  useEffect(() => () => view.destroy(), [])
  return view
}

/** adds an extension to a view and updates the extension anytime a dependency changes */
export function useExtension(view: EditorView, extensionCreator: () => Extension, deps: unknown[]) {
  const compartment = useMemo(() => new Compartment(), [])
  const extension = useMemo(extensionCreator, deps)

  useEffect(() => {
    if (!compartment.get(view.state)) {
      view.dispatch({ effects: StateEffect.appendConfig.of(compartment.of(extension)) })
    } else {
      view.dispatch({ effects: compartment.reconfigure(extension) })
    }
  }, [view, extension])
}

/** returns the EditorView connected to a dom node */
export const CodeMirrorElement: React.FC<{
  view: EditorView
  autoFocus: boolean
  className?: string
}> = ({ view, autoFocus, className }) => {
  const [domWrapper, setDomWrapper] = useState<HTMLDivElement | null>(null)
  const domWrapperNode = useCallback((node: HTMLDivElement | null) => {
    setDomWrapper(node)
  }, [])

  useLayoutEffect(() => {
    domWrapper?.appendChild(view.dom)
    autoFocus && view.focus()
    return () => {
      domWrapper?.firstElementChild && domWrapper?.removeChild(domWrapper.firstElementChild)
    }
  }, [domWrapper, view])

  return <div ref={domWrapperNode} className={className} />
}
