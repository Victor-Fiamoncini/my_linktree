function getZonedDateString(date, timeZone) {
	const parts = new Intl.DateTimeFormat('en-CA', {
		timeZone,
		year: 'numeric',
		month: '2-digit',
		day: '2-digit',
	}).formatToParts(date)

	const { year, month, day } = Object.fromEntries(parts.map(part => [part.type, part.value]))

	return `${year}-${month}-${day}`
}

function addDays(dateString, days) {
	const date = new Date(`${dateString}T12:00:00Z`)

	date.setUTCDate(date.getUTCDate() + days)

	return date.toISOString().slice(0, 10)
}

function getTimeZoneOffsetMs(date, timeZone) {
	const parts = new Intl.DateTimeFormat('en-US', {
		timeZone,
		hourCycle: 'h23',
		year: 'numeric',
		month: '2-digit',
		day: '2-digit',
		hour: '2-digit',
		minute: '2-digit',
		second: '2-digit',
	}).formatToParts(date)

	const { year, month, day, hour, minute, second } = Object.fromEntries(parts.map(part => [part.type, part.value]))

	const asUtc = Date.UTC(year, month - 1, day, hour, minute, second)

	return asUtc - date.getTime()
}

function zonedWallTimeToUtc(dateString, timeString, timeZone) {
	const naiveUtc = new Date(`${dateString}T${timeString}:00Z`)
	const offsetMs = getTimeZoneOffsetMs(naiveUtc, timeZone)

	return new Date(naiveUtc.getTime() - offsetMs)
}

function minutesToTimeString(minutes) {
	const hours = Math.floor(minutes / 60)
	const remainder = minutes % 60

	return `${String(hours).padStart(2, '0')}:${String(remainder).padStart(2, '0')}`
}

function parseTimeToMinutes(timeString) {
	const [hours, minutes] = timeString.split(':').map(Number)

	return hours * 60 + minutes
}

export class CheckAvailabilityUseCase {
	#bookingStore
	#availabilityConfig

	constructor({ bookingStore, availabilityConfig }) {
		this.#bookingStore = bookingStore
		this.#availabilityConfig = availabilityConfig
	}

	async execute() {
		const { timezone, slotDurationMinutes, weeklyWindows, bookingHorizonDays } = this.#availabilityConfig

		const now = new Date()
		const todayString = getZonedDateString(now, timezone)
		const horizonEnd = addDays(todayString, bookingHorizonDays)
		const horizonEndEpochMs = zonedWallTimeToUtc(horizonEnd, '23:59', timezone).getTime()

		const bookings = await this.#bookingStore.listUpcoming({
			fromEpochMs: now.getTime(),
			toEpochMs: horizonEndEpochMs,
		})
		const bookedSlots = new Set(bookings.map(booking => booking.slotStart))

		const slots = []

		for (let dayOffset = 0; dayOffset < bookingHorizonDays; dayOffset++) {
			const dateString = addDays(todayString, dayOffset)
			const weekday = new Date(`${dateString}T12:00:00Z`).getUTCDay()
			const windows = weeklyWindows.filter(window => window.weekday === weekday)

			for (const window of windows) {
				const startMinutes = parseTimeToMinutes(window.start)
				const endMinutes = parseTimeToMinutes(window.end)

				for (let minutes = startMinutes; minutes + slotDurationMinutes <= endMinutes; minutes += slotDurationMinutes) {
					const slotStart = zonedWallTimeToUtc(dateString, minutesToTimeString(minutes), timezone)
					const slotStartIso = slotStart.toISOString()

					if (slotStart <= now || bookedSlots.has(slotStartIso)) {
						continue
					}

					slots.push(slotStartIso)
				}
			}
		}

		return { timezone, slots }
	}
}
