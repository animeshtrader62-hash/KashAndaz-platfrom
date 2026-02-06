import { useMemo, useState } from 'react'

export type SafeImageProps = {
  src?: string | null
  alt?: string
  className?: string
  imgClassName?: string
  fallbackClassName?: string
  onLoad?: () => void
  onError?: () => void
}

function PlaceholderIcon({ className }: { className?: string }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      className={className}
      aria-hidden="true"
    >
      <path
        d="M21 19V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2Z"
        stroke="currentColor"
        strokeWidth="1.5"
      />
      <path
        d="M7.5 10.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z"
        stroke="currentColor"
        strokeWidth="1.5"
      />
      <path
        d="M21 16.5 16.5 12l-6 6-3-3-4.5 4.5"
        stroke="currentColor"
        strokeWidth="1.5"
        strokeLinejoin="round"
      />
    </svg>
  )
}

export function SafeImage({
  src,
  alt,
  className,
  imgClassName,
  fallbackClassName,
  onLoad,
  onError,
}: SafeImageProps) {
  const [brokenSrc, setBrokenSrc] = useState<string | null>(null)

  const normalizedSrc = useMemo(() => (src ?? '').trim(), [src])
  const showImg = Boolean(normalizedSrc) && brokenSrc !== normalizedSrc

  return (
    <div className={className}>
      {showImg ? (
        <img
          src={normalizedSrc}
          alt={alt ?? ''}
          className={imgClassName}
          loading="lazy"
          onLoad={() => {
            onLoad?.()
          }}
          onError={() => {
            setBrokenSrc(normalizedSrc)
            onError?.()
          }}
        />
      ) : (
        <div className={fallbackClassName ?? 'flex h-full w-full items-center justify-center text-slate-400'}>
          <PlaceholderIcon className="h-5 w-5" />
        </div>
      )}
    </div>
  )
}
