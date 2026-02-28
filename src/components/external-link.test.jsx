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

	it('passes size={32} to the icon component', () => {
		render(<ExternalLink icon={MockIcon} link="https://example.com" />)

		expect(screen.getByTestId('link-icon')).toHaveAttribute('width', '32')
		expect(screen.getByTestId('link-icon')).toHaveAttribute('height', '32')
	})

	it('renders different links correctly', () => {
		const links = ['https://linkedin.com/in/victor', 'https://github.com/victor', 'https://instagram.com/victor']

		links.forEach(link => {
			const { unmount } = render(<ExternalLink icon={MockIcon} link={link} />)
			expect(screen.getByRole('link')).toHaveAttribute('href', link)
			unmount()
		})
	})
})
