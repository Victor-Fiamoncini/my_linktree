import { describe, it, expect, beforeEach } from 'vitest'

import { MemoryDatabase } from '@/core/infrastructure/database/memory-database'

describe('MemoryDatabase', () => {
	let db

	beforeEach(() => {
		db = new MemoryDatabase()
	})

	it('should return a profile object', async () => {
		const profile = await db.getProfile()

		expect(profile).toBeDefined()
		expect(typeof profile).toBe('object')
	})

	it('should include required top-level fields', async () => {
		const profile = await db.getProfile()

		expect(profile).toHaveProperty('name')
		expect(profile).toHaveProperty('experiences')
		expect(profile).toHaveProperty('education')
	})

	it('should return experiences as a non-empty array', async () => {
		const { experiences } = await db.getProfile()

		expect(Array.isArray(experiences)).toBe(true)
		expect(experiences.length).toBeGreaterThan(0)
	})

	it('should return each experience with required fields', async () => {
		const { experiences } = await db.getProfile()

		for (const exp of experiences) {
			expect(exp).toHaveProperty('id')
			expect(exp).toHaveProperty('company')
			expect(exp).toHaveProperty('role')
			expect(exp).toHaveProperty('backend')
			expect(exp).toHaveProperty('frontend')
			expect(exp).toHaveProperty('infra')
			expect(exp).toHaveProperty('otherTools')
			expect(exp).toHaveProperty('startDate')
			expect(exp).toHaveProperty('current')
		}
	})

	it('should return education as a non-empty array', async () => {
		const { education } = await db.getProfile()

		expect(Array.isArray(education)).toBe(true)
		expect(education.length).toBeGreaterThan(0)
	})

	it('should return each education entry with required fields', async () => {
		const { education } = await db.getProfile()

		for (const entry of education) {
			expect(entry).toHaveProperty('id')
			expect(entry).toHaveProperty('institution')
			expect(entry).toHaveProperty('degree')
			expect(entry).toHaveProperty('field')
		}
	})

	it('should return each experience with a non-empty description string', async () => {
		const { experiences } = await db.getProfile()

		for (const exp of experiences) {
			expect(typeof exp.description).toBe('string')
			expect(exp.description.trim().length).toBeGreaterThan(0)
		}
	})

	it('should return the same profile on repeated calls', async () => {
		const first = await db.getProfile()
		const second = await db.getProfile()

		expect(first).toEqual(second)
	})
})
