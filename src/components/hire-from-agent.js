'use client'

import { useState } from 'react'

import { AGENTS_MD_CONTENT } from '@/app/agents-content'

export default function HireFromAgent() {
	const [copied, setCopied] = useState(false)

	const handleCopy = async () => {
		try {
			await navigator.clipboard.writeText(AGENTS_MD_CONTENT)

			setCopied(true)

			setTimeout(() => setCopied(false), 2000)
		} catch {
			// The browser can deny clipboard access; the snippet is still selectable/readable.
		}
	}

	return (
		<section id="agents" className="w-full max-w-3xl text-center">
			<div className="border-4 border-black bg-white p-8 shadow-[6px_6px_0px_0px_#60a5fa]">
				<h2 className="mb-6 text-2xl font-bold tracking-widest text-black uppercase sm:text-3xl">
					Hire me from your agent 🤖
				</h2>

				<p className="mb-6 text-justify text-sm text-gray-700">
					This portfolio speaks MCP. Point your AI agent at the endpoint below to read my resume, check my services and
					availability, and book a presentation — no human required.
				</p>

				<div className="w-full text-left">
					<div className="flex items-center justify-between border-4 border-b-0 border-black bg-[#181825] px-4 py-2">
						<div className="flex items-center gap-3">
							<span className="flex gap-1.5">
								<span className="h-2.5 w-2.5 rounded-full bg-[#f38ba8]" />
								<span className="h-2.5 w-2.5 rounded-full bg-[#f9e2af]" />
								<span className="h-2.5 w-2.5 rounded-full bg-[#a6e3a1]" />
							</span>

							<span className="text-xs font-bold tracking-widest text-[#cdd6f4]">AGENTS.md</span>
						</div>

						<button
							type="button"
							onClick={handleCopy}
							title="Copy AGENTS.md"
							className={`cursor-pointer text-xs font-bold tracking-widest uppercase transition-colors ${
								copied ? 'text-[#a6e3a1]' : 'text-[#89b4fa] hover:text-[#cdd6f4]'
							}`}
						>
							{copied ? 'Copied!' : 'Copy'}
						</button>
					</div>

					<pre className="w-full overflow-x-auto border-4 border-black bg-[#1e1e2e] p-4 text-xs leading-relaxed font-semibold text-[#a6e3a1]">
						<code>{AGENTS_MD_CONTENT}</code>
					</pre>
				</div>
			</div>
		</section>
	)
}
