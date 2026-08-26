import { describe, it, expect, vi, beforeAll, beforeEach, afterEach } from 'vitest'

const captured = vi.hoisted(() => ({ initializeServer: null }))
const mockHandlerFn = vi.hoisted(() => vi.fn())

vi.mock('mcp-handler', () => ({
	createMcpHandler: initializeServer => {
		captured.initializeServer = initializeServer
		return mockHandlerFn
	},
}))

const mockListUpcoming = vi.hoisted(() => vi.fn())
const mockBook = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/scheduling/upstash-booking-store', () => ({
	UpstashBookingStore: class {
		constructor() {
			this.listUpcoming = mockListUpcoming
			this.book = mockBook
		}
	},
}))

const mockRecord = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/telemetry/upstash-connection-log', () => ({
	UpstashConnectionLog: class {
		constructor() {
			this.record = mockRecord
		}
	},
}))

const mockSendEmail = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/mailer/resend-mailer', () => ({
	ResendMailer: class {
		constructor() {
			this.sendEmail = mockSendEmail
		}
	},
}))

const mockGeneralIsAllowed = vi.hoisted(() => vi.fn())
const mockScheduleIsAllowed = vi.hoisted(() => vi.fn())

vi.mock('@/core/infrastructure/rate-limiter/upstash-rate-limiter', () => ({
	UpstashRateLimiter: class {
		constructor({ maxRequests }) {
			this.isAllowed = maxRequests === 30 ? mockGeneralIsAllowed : mockScheduleIsAllowed
		}
	},
}))

const { POST, GET } = await import('@/app/api/mcp/route')

const makeMcpRequest = (body, headers = {}) =>
	new Request('http://localhost/api/mcp', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json', ...headers },
		body: JSON.stringify(body),
	})

const toolsCallBody = (name, args = {}) => ({
	jsonrpc: '2.0',
	id: 1,
	method: 'tools/call',
	params: { name, arguments: args },
})

const ip = addr => ({ 'x-forwarded-for': addr })

const VALID_SLOT_START = '2026-03-02T12:00:00.000Z'

describe('MCP route', () => {
	let tools

	beforeAll(() => {
		tools = {}
		captured.initializeServer({
			registerTool(name, config, handler) {
				tools[name] = { config, handler }
			},
		})
	})

	beforeEach(() => {
		mockRecord.mockReset().mockResolvedValue(undefined)
		mockListUpcoming.mockReset().mockResolvedValue([])
		mockBook.mockReset().mockResolvedValue(true)
		mockSendEmail.mockReset().mockResolvedValue(undefined)
		mockGeneralIsAllowed.mockReset().mockResolvedValue(true)
		mockScheduleIsAllowed.mockReset().mockResolvedValue(true)
		mockHandlerFn.mockReset().mockResolvedValue(new Response(null, { status: 200 }))
	})

	describe('tool registration', () => {
		it('registers get_resume, list_services, check_availability and schedule_meeting', () => {
			expect(Object.keys(tools)).toEqual(['get_resume', 'list_services', 'check_availability', 'schedule_meeting'])
		})
	})

	describe('get_resume tool', () => {
		it('records the agent connection', async () => {
			await tools.get_resume.handler({})

			expect(mockRecord).toHaveBeenCalledWith(expect.objectContaining({ tool: 'get_resume' }))
		})

		it('returns the profile as JSON text content', async () => {
			const result = await tools.get_resume.handler({})
			const profile = JSON.parse(result.content[0].text)

			expect(profile.name).toBe('Victor Fiamoncini')
			expect(Array.isArray(profile.experiences)).toBe(true)
		})
	})

	describe('list_services tool', () => {
		it('records the agent connection', async () => {
			await tools.list_services.handler({})

			expect(mockRecord).toHaveBeenCalledWith(expect.objectContaining({ tool: 'list_services' }))
		})

		it('returns the services as JSON text content', async () => {
			const result = await tools.list_services.handler({})
			const services = JSON.parse(result.content[0].text)

			expect(services).toEqual([
				{ id: 1, name: expect.any(String), description: expect.any(String) },
				{ id: 2, name: expect.any(String), description: expect.any(String) },
				{ id: 3, name: expect.any(String), description: expect.any(String) },
				{ id: 4, name: expect.any(String), description: expect.any(String) },
			])
		})
	})

	describe('check_availability tool', () => {
		beforeEach(() => {
			vi.useFakeTimers()
			vi.setSystemTime(new Date('2026-03-02T10:00:00.000Z'))
		})

		afterEach(() => {
			vi.useRealTimers()
		})

		it('records the agent connection', async () => {
			await tools.check_availability.handler({})

			expect(mockRecord).toHaveBeenCalledWith(expect.objectContaining({ tool: 'check_availability' }))
		})

		it('returns the timezone and free slots as JSON text content', async () => {
			const result = await tools.check_availability.handler({})
			const availability = JSON.parse(result.content[0].text)

			expect(availability.timezone).toBe('America/Sao_Paulo')
			expect(availability.slots).toContain(VALID_SLOT_START)
		})
	})

	describe('schedule_meeting tool', () => {
		beforeEach(() => {
			vi.useFakeTimers()
			vi.setSystemTime(new Date('2026-03-02T10:00:00.000Z'))
		})

		afterEach(() => {
			vi.useRealTimers()
		})

		it('records the agent connection', async () => {
			await tools.schedule_meeting.handler({
				name: 'John Doe',
				email: 'john@example.com',
				slotStart: VALID_SLOT_START,
			})

			expect(mockRecord).toHaveBeenCalledWith(expect.objectContaining({ tool: 'schedule_meeting' }))
		})

		it('books the slot and returns the booking as JSON text content', async () => {
			const result = await tools.schedule_meeting.handler({
				name: 'John Doe',
				email: 'john@example.com',
				slotStart: VALID_SLOT_START,
			})
			const booking = JSON.parse(result.content[0].text)

			expect(booking).toEqual({
				name: 'John Doe',
				email: 'john@example.com',
				company: null,
				slotStart: VALID_SLOT_START,
			})
			expect(mockBook).toHaveBeenCalledOnce()
		})

		it('sends confirmation and notification emails', async () => {
			await tools.schedule_meeting.handler({
				name: 'John Doe',
				email: 'john@example.com',
				slotStart: VALID_SLOT_START,
			})

			expect(mockSendEmail).toHaveBeenCalledTimes(2)
		})

		it('rejects when required fields are missing', async () => {
			await expect(tools.schedule_meeting.handler({})).rejects.toThrow()

			expect(mockBook).not.toHaveBeenCalled()
		})

		it('rejects when the slot is unavailable', async () => {
			await expect(
				tools.schedule_meeting.handler({
					name: 'John Doe',
					email: 'john@example.com',
					slotStart: '2026-03-02T23:00:00.000Z',
				})
			).rejects.toThrow()

			expect(mockBook).not.toHaveBeenCalled()
		})
	})

	describe('POST — rate limiting', () => {
		it('forwards allowed requests to the MCP handler', async () => {
			const request = makeMcpRequest(toolsCallBody('get_resume'), ip('1.2.3.4'))

			await POST(request)

			expect(mockHandlerFn).toHaveBeenCalledWith(request)
		})

		it('returns 429 when the general rate limiter blocks the request', async () => {
			mockGeneralIsAllowed.mockResolvedValue(false)

			const response = await POST(makeMcpRequest(toolsCallBody('get_resume'), ip('1.2.3.4')))

			expect(response.status).toBe(429)
			expect(mockHandlerFn).not.toHaveBeenCalled()
		})

		it('returns a TooManyRequestsError body when the general limiter blocks', async () => {
			mockGeneralIsAllowed.mockResolvedValue(false)

			const response = await POST(makeMcpRequest(toolsCallBody('get_resume'), ip('1.2.3.4')))
			const body = await response.json()

			expect(body).toMatchObject({ name: 'TooManyRequestsError', message: 'Too many requests' })
		})

		it('returns 429 when the schedule limiter blocks a schedule_meeting call', async () => {
			mockScheduleIsAllowed.mockResolvedValue(false)

			const response = await POST(makeMcpRequest(toolsCallBody('schedule_meeting'), ip('1.2.3.4')))

			expect(response.status).toBe(429)
			expect(mockHandlerFn).not.toHaveBeenCalled()
		})

		it('does not apply the schedule limiter to other tool calls', async () => {
			mockScheduleIsAllowed.mockResolvedValue(false)

			const response = await POST(makeMcpRequest(toolsCallBody('get_resume'), ip('1.2.3.4')))

			expect(response.status).not.toBe(429)
			expect(mockHandlerFn).toHaveBeenCalled()
		})

		it('skips rate limiting when no IP header is present', async () => {
			mockGeneralIsAllowed.mockResolvedValue(false)

			const response = await POST(makeMcpRequest(toolsCallBody('get_resume')))

			expect(response.status).not.toBe(429)
			expect(mockHandlerFn).toHaveBeenCalled()
		})
	})

	describe('GET', () => {
		it('is the raw MCP handler', () => {
			expect(GET).toBe(mockHandlerFn)
		})
	})
})
