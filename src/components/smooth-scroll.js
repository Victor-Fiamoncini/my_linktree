'use client'

import { useEffect } from 'react'
import Lenis from 'lenis'

let lenisInstance = null

export const HEADER_SCROLL_OFFSET = -96

export function getLenis() {
	return lenisInstance
}

export default function SmoothScroll() {
	useEffect(() => {
		const lenis = new Lenis()

		lenisInstance = lenis

		let frameId

		function raf(time) {
			lenis.raf(time)
			frameId = requestAnimationFrame(raf)
		}

		frameId = requestAnimationFrame(raf)

		return () => {
			cancelAnimationFrame(frameId)
			lenis.destroy()
			lenisInstance = null
		}
	}, [])

	return null
}
