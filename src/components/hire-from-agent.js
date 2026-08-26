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
		<section id="agents" className="border-ctp-surface0 w-full max-w-[1080px] border-t pt-14 pb-14">
			<p className="text-ctp-peach mb-3.5 font-mono text-[13px] tracking-[0.06em]">$ ./hire-me --no-human-required</p>

			<h2 className="text-ctp-text mb-4 text-[28px] font-semibold tracking-[-0.025em] min-[900px]:text-[34px]">
				Hire me from your agent
			</h2>

			<p className="text-ctp-subtext0 mb-8 max-w-[62ch] text-[17px] leading-[1.7] text-pretty">
				This portfolio speaks MCP. Point your AI agent at the endpoint below to read my resume, check my services and
				availability, and book a meeting — no human required.
			</p>

			<div className="w-full text-left">
				<div className="border-ctp-surface0 rounded-t-btn flex items-center justify-between border border-b-0 bg-[#181825] px-4 py-2">
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

				<pre className="border-ctp-surface0 rounded-b-btn w-full overflow-x-auto border bg-[#1e1e2e] p-4 text-xs leading-relaxed font-semibold text-[#a6e3a1]">
					<code>{AGENTS_MD_CONTENT}</code>
				</pre>
			</div>
		</section>
	)
}
