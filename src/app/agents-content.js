import { MCP_ENDPOINT, SITE_URL } from '@/app/seo-config'

export const AGENTS_MD_CONTENT = `# AGENTS.md — hire Victor Fiamoncini

MCP endpoint: ${MCP_ENDPOINT}

Connect with any MCP-compatible client:

{
  "victor-fiamoncini": {
    "url": "${MCP_ENDPOINT}"
  }
}

Available tools:
- get_resume             Structured resume/CV as JSON
- list_services          Services offered
- check_availability     Open meeting slots (America/Sao_Paulo)
- schedule_meeting       Book a meeting

Services: Frontend & Backend Software Development, Agentic Systems & Integrations, Websites & Landing Pages, Mobile Apps

Watch live agent connections: ${SITE_URL}/telemetry
`
