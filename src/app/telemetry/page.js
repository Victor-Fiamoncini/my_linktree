import TelemetryFeed from '@/components/telemetry-feed'

const TelemetryPage = () => (
	<main className="flex flex-1 flex-col items-center justify-center gap-8 px-4 py-12">
		<section className="w-full max-w-3xl border-4 border-black bg-white p-8 text-center shadow-[6px_6px_0px_0px_#60a5fa]">
			<h1 className="mb-6 text-2xl font-bold tracking-widest text-black uppercase sm:text-3xl">
				Live Agent Telemetry 🤖
			</h1>

			<p className="mb-6 text-sm text-gray-700">Watch which AI agents are connecting to the MCP server in real time.</p>

			<TelemetryFeed />
		</section>
	</main>
)

export default TelemetryPage
