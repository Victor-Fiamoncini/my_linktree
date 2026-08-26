'use client'

import { useEffect, useState } from 'react'

const POLL_INTERVAL_MS = 5000

export default function TelemetryFeed() {
	const [connections, setConnections] = useState([])
	const [status, setStatus] = useState('loading') // 'loading', 'ready', 'error'

	useEffect(() => {
		let isMounted = true

		const fetchConnections = async () => {
			try {
				const response = await fetch('/api/telemetry')

				if (!response.ok) {
					throw new Error('Failed to fetch telemetry')
				}

				const data = await response.json()

				if (isMounted) {
					setConnections(data)
					setStatus('ready')
				}
			} catch {
				if (isMounted) {
					setStatus('error')
				}
			}
		}

		fetchConnections()

		const intervalId = setInterval(fetchConnections, POLL_INTERVAL_MS)

		return () => {
			isMounted = false
			clearInterval(intervalId)
		}
	}, [])

	if (status === 'loading') {
		return <p className="text-ctp-overlay0 py-2 font-mono text-xs"># loading live telemetry...</p>
	}

	if (status === 'error') {
		return (
			<p className="text-ctp-red py-2 font-mono text-xs"># error: something went wrong while loading live telemetry.</p>
		)
	}

	if (connections.length === 0) {
		return <p className="text-ctp-overlay0 py-2 font-mono text-xs"># no agent connections yet.</p>
	}

	return (
		<ul data-lenis-prevent className="flex max-h-96 w-full flex-col overflow-y-auto">
			{connections.map((connection, index) => (
				<li
					key={`${connection.tool}-${connection.timestamp}-${index}`}
					className="border-ctp-surface1/40 flex flex-wrap items-baseline gap-x-3 gap-y-1 border-b border-dashed py-2 font-mono text-xs last:border-b-0"
				>
					<span className="text-ctp-green">➜</span>
					<span className="text-ctp-text break-words">{connection.tool}</span>
					<span className="text-ctp-overlay0 ml-auto whitespace-nowrap max-[424px]:ml-0 max-[424px]:w-full">
						{new Date(connection.timestamp).toLocaleString()}
					</span>
				</li>
			))}
		</ul>
	)
}
