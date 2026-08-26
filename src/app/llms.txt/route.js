import { AGENTS_MD_CONTENT } from '@/app/agents-content'

export async function GET() {
	return new Response(AGENTS_MD_CONTENT, {
		status: 200,
		headers: { 'Content-Type': 'text/markdown; charset=utf-8' },
	})
}
