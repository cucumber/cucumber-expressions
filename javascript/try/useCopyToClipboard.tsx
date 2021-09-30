// https://www.benmvp.com/blog/copy-to-clipboard-react-custom-hook/
import React, { useCallback, useEffect, useState } from 'react'

export type CopyStatus = 'inactive' | 'copied' | 'failed'
type CopyStatusText = Record<CopyStatus, string>

export const CopyButton: React.FunctionComponent<{
  copyStatusText: CopyStatusText
  copyText: () => string
}> = ({ copyStatusText, copyText }) => {
  const [copyStatus, copy] = useCopyToClipboard(copyText)

  return (
    <button
      className="inline-flex items-center px-2.5 py-1.5 border border-gray-500 shadow-sm text-xs font-medium rounded text-gray-700 bg-white hover:bg-gray-50"
      onClick={copy}
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        className="h-6 w-6 pr-1"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          strokeWidth={2}
          d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
        />
      </svg>
      {copyStatusText[copyStatus]}
    </button>
  )
}

export function useCopyToClipboard(
  copyText: () => string,
  notifyTimeout = 1500
): [CopyStatus, () => void] {
  const [copyStatus, setCopyStatus] = useState<CopyStatus>('inactive')
  const copy = useCallback(() => {
    navigator.clipboard
      .writeText(copyText())
      .then(() => setCopyStatus('copied'))
      .catch(() => setCopyStatus('failed'))
  }, [copyText])

  useEffect(() => {
    if (copyStatus === 'inactive') {
      return
    }

    const timeoutId = setTimeout(() => setCopyStatus('inactive'), notifyTimeout)

    return () => clearTimeout(timeoutId)
  }, [copyStatus, notifyTimeout])

  return [copyStatus, copy]
}
