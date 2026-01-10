import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest'

import { GetXpYearsUseCase } from './get-xp-years-use-case'

describe('GetXpYearsUseCase', () => {
  let useCase

  beforeEach(() => {
    useCase = new GetXpYearsUseCase()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('should have startYearOfWork equal to 2019', () => {
    expect(useCase.startYearOfWork).toBe(2019)
  })

  it('should calculate years of experience correctly', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2024, 0, 1))

    const years = useCase.execute()

    expect(years).toBe(5)
  })

  it('should return 0 when current year equals start year', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2019, 0, 1))

    const years = useCase.execute()

    expect(years).toBe(0)
  })

  it('should return correct value for different years', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2030, 5, 15))

    const years = useCase.execute()

    expect(years).toBe(11)
  })
})
