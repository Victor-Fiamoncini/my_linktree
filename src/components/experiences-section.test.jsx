// @vitest-environment jsdom

import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, it, expect } from 'vitest'

import ExperiencesSection from '@/components/experiences-section'

const makeExperience = overrides => ({
	id: 1,
	company: 'Acme Corp',
	role: 'Software Engineer',
	backend: ['Node.js'],
	frontend: [],
	infra: [],
	otherTools: [],
	location: 'Remote',
	startDate: '2023-01',
	endDate: null,
	current: true,
	durationLabel: '1 year',
	description: 'Worked on cool things at Acme.',
	...overrides,
})

describe('ExperiencesSection', () => {
	describe('description', () => {
		it('renders the description text for the active experience', () => {
			render(<ExperiencesSection experiences={[makeExperience()]} />)

			expect(screen.getByText('Worked on cool things at Acme.')).toBeInTheDocument()
		})

		it('does not render a description when it is null', () => {
			render(<ExperiencesSection experiences={[makeExperience({ description: null })]} />)

			expect(screen.queryByText('Worked on cool things at Acme.')).not.toBeInTheDocument()
		})

		it('shows the description of the selected tab and hides others', async () => {
			const user = userEvent.setup()

			const experiences = [
				makeExperience({ id: 1, company: 'Acme Corp', description: 'Acme description.' }),
				makeExperience({ id: 2, company: 'Beta Ltd', description: 'Beta description.' }),
			]

			render(<ExperiencesSection experiences={experiences} />)

			expect(screen.getByText('Acme description.')).toBeInTheDocument()
			expect(screen.queryByText('Beta description.')).not.toBeInTheDocument()

			await user.click(screen.getByRole('button', { name: 'Beta Ltd' }))

			expect(screen.queryByText('Acme description.')).not.toBeInTheDocument()
			expect(screen.getByText('Beta description.')).toBeInTheDocument()
		})
	})
})
