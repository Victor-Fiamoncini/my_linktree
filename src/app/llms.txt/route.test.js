import { describe, it, expect } from 'vitest'

import { GET } from '@/app/llms.txt/route'
import { AGENTS_MD_CONTENT } from '@/app/agents-content'

describe('GET /llms.txt', () => {
	it('returns 200 with the AGENTS.md content as markdown', async () => {
		const response = await GET()
		const body = await response.text()

		expect(response.status).toBe(200)
		expect(response.headers.get('Content-Type')).toBe('text/markdown; charset=utf-8')
		expect(body).toBe(AGENTS_MD_CONTENT)
	})

	it('includes the MCP endpoint', async () => {
		const response = await GET()
		const body = await response.text()

		expect(body).toContain('https://www.victorfiamon.com.br/api/mcp')
	})
})
