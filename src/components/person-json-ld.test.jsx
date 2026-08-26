// @vitest-environment jsdom

import { render } from '@testing-library/react'
import { describe, it, expect } from 'vitest'

import PersonJsonLd from '@/components/person-json-ld'

describe('PersonJsonLd', () => {
	it('renders a script tag with type application/ld+json', () => {
		const { container } = render(<PersonJsonLd />)
		const script = container.querySelector('script[type="application/ld+json"]')

		expect(script).not.toBeNull()
	})

	it('embeds valid JSON with a Person and WebSite node', () => {
		const { container } = render(<PersonJsonLd />)
		const json = JSON.parse(container.querySelector('script').innerHTML)
		const types = json['@graph'].map(node => node['@type'])

		expect(types).toEqual(['Person', 'WebSite'])
	})
})
