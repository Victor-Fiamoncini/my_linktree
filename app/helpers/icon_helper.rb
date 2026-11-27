module IconHelper
  ICONS = {
    github: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M12 .5C5.73.5.75 5.48.75 11.75c0 5.02 3.26 9.28 7.78 10.78.57.1.78-.25.78-.55v-2.14c-3.16.69-3.83-1.36-3.83-1.36-.52-1.31-1.26-1.66-1.26-1.66-1.03-.7.08-.69.08-.69 1.14.08 1.74 1.17 1.74 1.17 1.01 1.73 2.65 1.23 3.3.94.1-.73.4-1.23.72-1.51-2.52-.29-5.17-1.26-5.17-5.62 0-1.24.44-2.26 1.17-3.06-.12-.29-.51-1.45.11-3.02 0 0 .96-.31 3.13 1.17a10.87 10.87 0 0 1 5.7 0c2.17-1.48 3.13-1.17 3.13-1.17.62 1.57.23 2.73.11 3.02.73.8 1.17 1.82 1.17 3.06 0 4.37-2.66 5.33-5.19 5.61.41.35.77 1.05.77 2.11v3.13c0 .3.21.66.79.55 4.52-1.5 7.77-5.76 7.77-10.78C23.25 5.48 18.27.5 12 .5Z"/></svg>'.html_safe,
    linkedin: '<svg viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M20.45 20.45h-3.55v-5.57c0-1.33-.02-3.03-1.85-3.03-1.86 0-2.14 1.45-2.14 2.94v5.66H9.36V9h3.41v1.56h.05c.48-.9 1.64-1.85 3.37-1.85 3.6 0 4.27 2.37 4.27 5.46v6.28ZM5.34 7.43a2.06 2.06 0 1 1 0-4.12 2.06 2.06 0 0 1 0 4.12ZM7.12 20.45H3.56V9h3.56v11.45ZM22.22 0H1.77C.8 0 0 .78 0 1.75v20.5C0 23.22.8 24 1.77 24h20.45c.98 0 1.78-.78 1.78-1.75V1.75C24 .78 23.2 0 22.22 0Z"/></svg>'.html_safe,
    # Pixel sprites: drawn on a tiny grid and scaled up with crispEdges, so they stay sharp at any size
    bars: '<svg viewBox="0 0 7 7" shape-rendering="crispEdges" fill="currentColor" aria-hidden="true"><path d="M0 0h7v1H0z M0 3h7v1H0z M0 6h7v1H0z"/></svg>'.html_safe,
    times: '<svg viewBox="0 0 7 7" shape-rendering="crispEdges" fill="currentColor" aria-hidden="true"><path d="M0 0h1v1H0z M1 1h1v1H1z M2 2h1v1H2z M3 3h1v1H3z M4 4h1v1H4z M5 5h1v1H5z M6 6h1v1H6z M6 0h1v1H6z M5 1h1v1H5z M4 2h1v1H4z M2 4h1v1H2z M1 5h1v1H1z M0 6h1v1H0z"/></svg>'.html_safe,
    sun: '<svg viewBox="0 0 9 9" shape-rendering="crispEdges" fill="currentColor" aria-hidden="true"><path d="M3 3h3v3H3z M4 0h1v2H4z M4 7h1v2H4z M0 4h2v1H0z M7 4h2v1H7z M1 1h1v1H1z M7 1h1v1H7z M1 7h1v1H1z M7 7h1v1H7z"/></svg>'.html_safe,
    moon: '<svg viewBox="0 0 8 8" shape-rendering="crispEdges" fill="currentColor" aria-hidden="true"><path d="M2 0h3v1H2z M1 1h2v1H1z M0 2h2v3H0z M0 5h3v1H0z M7 5h1v1H7z M1 6h6v1H1z M2 7h4v1H2z"/></svg>'.html_safe,
    cursor: '<svg viewBox="0 0 4 7" shape-rendering="crispEdges" fill="currentColor" aria-hidden="true"><path d="M0 0h1v7H0z M1 1h1v5H1z M2 2h1v3H2z M3 3h1v1H3z"/></svg>'.html_safe,
    caret_down: '<svg viewBox="0 0 7 4" shape-rendering="crispEdges" fill="currentColor" aria-hidden="true"><path d="M0 0h7v1H0z M1 1h5v1H1z M2 2h3v1H2z M3 3h1v1H3z"/></svg>'.html_safe,
    envelope: '<svg viewBox="0 0 9 7" shape-rendering="crispEdges" fill="currentColor" fill-rule="evenodd" aria-hidden="true"><path d="M0 0h9v7H0z M1 1h7v5H1z M1 1h1v1H1z M2 2h1v1H2z M3 3h3v1H3z M6 2h1v1H6z M7 1h1v1H7z"/></svg>'.html_safe
  }.freeze

  def svg_icon(name)
    ICONS.fetch(name)
  end
end
