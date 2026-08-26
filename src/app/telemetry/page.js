import TelemetryFeed from '@/components/telemetry-feed'

export const metadata = {
	title: 'Live Agent Telemetry',
	description:
		"Watch AI agents connect to Victor Fiamoncini's MCP server in real time — tool calls, timestamps, and live activity.",
	alternates: {
		canonical: '/telemetry',
	},
	openGraph: {
		title: 'Live Agent Telemetry — Victor Fiamoncini',
		description: 'Watch AI agents connect to the MCP server in real time.',
		url: '/telemetry',
		images: ['/opengraph-image'],
	},
	twitter: {
		title: 'Live Agent Telemetry — Victor Fiamoncini',
		images: ['/opengraph-image'],
	},
}

const TelemetryPage = () => (
	<main className="bg-ctp-base flex flex-1 flex-col items-center px-8 py-16">
		<section className="w-full max-w-[720px]">
			<p className="text-ctp-pink mb-3.5 font-mono text-[13px] tracking-[0.06em]">$ tail -f /var/log/agents.log</p>

			<h1 className="text-ctp-text mb-4 text-[28px] font-semibold tracking-[-0.025em] sm:text-[34px]">
				Live Agent Telemetry
			</h1>

			<p className="text-ctp-subtext0 mb-6 max-w-[58ch] text-[17px] leading-[1.7] text-pretty">
				Watch which AI agents are connecting to the MCP server in real time.
			</p>

			<div className="text-ctp-green mb-5 flex items-center gap-2 font-mono text-xs">
				<span className="relative flex h-2 w-2">
					<span className="bg-ctp-green absolute inline-flex h-full w-full animate-ping rounded-full opacity-75" />
					<span className="bg-ctp-green relative inline-flex h-2 w-2 rounded-full" />
				</span>
				live
			</div>

			<div className="text-left">
				<div className="border-ctp-surface0 rounded-t-btn flex items-center gap-3 border border-b-0 bg-[#181825] px-4 py-2">
					<span className="flex gap-1.5">
						<span className="h-2.5 w-2.5 rounded-full bg-[#f38ba8]" />
						<span className="h-2.5 w-2.5 rounded-full bg-[#f9e2af]" />
						<span className="h-2.5 w-2.5 rounded-full bg-[#a6e3a1]" />
					</span>

					<span className="text-xs font-bold tracking-widest text-[#cdd6f4]">agents.log</span>
				</div>

				<div className="border-ctp-surface0 rounded-b-btn border bg-[#1e1e2e] px-4 py-3">
					<TelemetryFeed />
				</div>
			</div>
		</section>
	</main>
)

export default TelemetryPage
