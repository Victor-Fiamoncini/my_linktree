// @vitest-environment jsdom

import { render, screen } from '@testing-library/react'
import { describe, it, expect } from 'vitest'

import ExternalLink from '@/components/external-link'

const MockIcon = ({ size }) => <svg data-testid="link-icon" width={size} height={size} aria-hidden="true" />

describe('ExternalLink', () => {
	it('renders an anchor element', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" />)

		expect(screen.getByRole('link')).toBeInTheDocument()
	})

	it('sets the correct href from the link prop', () => {
		render(<ExternalLink icon={MockIcon} link="https://linkedin.com/in/victor" />)

		expect(screen.getByRole('link')).toHaveAttribute('href', 'https://linkedin.com/in/victor')
	})

	it('opens the link in a new tab', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" />)

		expect(screen.getByRole('link')).toHaveAttribute('target', '_blank')
	})

	it('includes rel="noopener noreferrer" for security', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" />)

		expect(screen.getByRole('link')).toHaveAttribute('rel', 'noopener noreferrer')
	})

	it('renders the icon inside the link', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" />)

		expect(screen.getByTestId('link-icon')).toBeInTheDocument()
	})

	it('passes size={18} to the icon component', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" />)

		expect(screen.getByTestId('link-icon')).toHaveAttribute('width', '18')
		expect(screen.getByTestId('link-icon')).toHaveAttribute('height', '18')
	})

	it('renders different links correctly', () => {
		const links = ['https://linkedin.com/in/victor', 'https://github.com/victor']

		links.forEach(link => {
			const { unmount } = render(<ExternalLink icon={MockIcon} link={link} />)
			expect(screen.getByRole('link')).toHaveAttribute('href', link)
			unmount()
		})
	})

	it('renders the label when provided', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" label="LinkedIn" />)

		expect(screen.getByText('LinkedIn')).toBeInTheDocument()
	})

	it('does not render a label element when label is not provided', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" />)

		expect(screen.queryByText('LinkedIn')).not.toBeInTheDocument()
	})

	describe('card variant', () => {
		it('renders the label and handle', () => {
			render(
				<ExternalLink
					icon={MockIcon}
					link="https://linkedin.com/in/victor"
					label="LinkedIn"
					handle="@victor"
					variant="card"
				/>
			)

			expect(screen.getByText('LinkedIn')).toBeInTheDocument()
			expect(screen.getByText('@victor')).toBeInTheDocument()
		})

		it('does not render a handle element when handle is not provided', () => {
			render(<ExternalLink icon={MockIcon} link="https://example.com" label="GitHub" variant="card" />)

			expect(screen.queryByText('@victor')).not.toBeInTheDocument()
		})
	})
})
