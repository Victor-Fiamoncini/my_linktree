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
		return <p className="text-sm font-semibold text-gray-700">Loading live telemetry...</p>
	}

	if (status === 'error') {
		return (
			<p className="w-full border-4 border-black bg-red-400 px-4 py-3 text-sm font-bold text-black">
				Oops! Something went wrong while loading live telemetry.
			</p>
		)
	}

	if (connections.length === 0) {
		return <p className="text-sm font-semibold text-gray-700">No agent connections yet.</p>
	}

	return (
		<ul data-lenis-prevent className="flex max-h-96 w-full flex-col gap-3 overflow-y-auto pr-4">
			{connections.map((connection, index) => (
				<li
					key={`${connection.tool}-${connection.timestamp}-${index}`}
					className="flex w-full flex-col items-start justify-between gap-2 border-4 border-l-8 border-black border-l-blue-400 bg-white px-4 py-3 sm:flex-row sm:items-center"
				>
					<span className="max-w-full rounded-md border-2 border-black bg-blue-100 px-3 py-1 text-xs font-bold tracking-wide break-words text-black uppercase sm:tracking-widest">
						{connection.tool}
					</span>
					<span className="font-mono text-xs font-semibold text-gray-500">
						{new Date(connection.timestamp).toLocaleString()}
					</span>
				</li>
			))}
		</ul>
	)
}
