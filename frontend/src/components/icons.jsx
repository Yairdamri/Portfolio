import React from 'react'

const svgProps = {
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
  'aria-hidden': true,
  focusable: false,
}

export const LogoIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M12 2l2.5 5 5 .8-3.6 3.6.9 5.1L12 14.8 7.2 16.5l.9-5.1L4.5 7.8l5-.8L12 2z" fill="currentColor" stroke="none"/></svg>
)

export const WandIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M15 4l-11 11"/><path d="M2 14l3 3"/><path d="M14 2l3 3"/><path d="M20 9l2 2"/><path d="M9 20l2 2"/></svg>
)

export const DumbbellIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><rect x="1" y="8" width="4" height="8"/><rect x="19" y="8" width="4" height="8"/><rect x="7" y="10" width="10" height="4"/></svg>
)

export const HomeIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M3 10l9-7 9 7"/><path d="M5 10v10h14V10"/></svg>
)

export const BookIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M4 4h12a2 2 0 0 1 2 2v14H6a2 2 0 0 1-2-2V4z"/><path d="M6 18h12"/></svg>
)

export const CalendarIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M16 3v4M8 3v4M3 11h18"/></svg>
)

export const ClipboardIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><rect x="7" y="3" width="10" height="4" rx="1"/><rect x="4" y="7" width="16" height="14" rx="2"/></svg>
)

export const ChevronRightIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M9 6l6 6-6 6"/></svg>
)

export const ChevronDownIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M6 9l6 6 6-6"/></svg>
)

export const PlayIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`} fill="currentColor" stroke="none"><path d="M8 5v14l11-7-11-7z"/></svg>
)

export const XIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M6 6l12 12M6 18L18 6"/></svg>
)

export const CheckIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M5 13l4 4L19 7"/></svg>
)

export const CheckCircleIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><circle cx="12" cy="12" r="10"/><path d="M9 12l2 2 4-4"/></svg>
)

export const CircleIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><circle cx="12" cy="12" r="10"/></svg>
)

export const TimerIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><circle cx="12" cy="13" r="8"/><path d="M12 9v5l3 2"/><path d="M10 2h4"/></svg>
)

export const ChartBarIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><rect x="3" y="10" width="4" height="10"/><rect x="10" y="6" width="4" height="14"/><rect x="17" y="3" width="4" height="17"/></svg>
)

export const RefreshIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M20 11a8 8 0 1 1-2-5.3"/><path d="M20 4v7h-7"/></svg>
)

export const SaveIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M5 4h11l3 3v13H5z"/><path d="M9 4v6h6V4"/></svg>
)

export const ArrowRightIcon = (props) => (
  <svg {...svgProps} className={`icon ${props.className || ''}`}><path d="M5 12h14"/><path d="M13 5l7 7-7 7"/></svg>
)
