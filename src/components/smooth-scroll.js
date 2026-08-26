'use client'

import { useEffect } from 'react'
import Lenis from 'lenis'

export default function SmoothScroll() {
	useEffect(() => {
		const lenis = new Lenis()

		let frameId

		function raf(time) {
			lenis.raf(time)
			frameId = requestAnimationFrame(raf)
		}

		frameId = requestAnimationFrame(raf)

		return () => {
			cancelAnimationFrame(frameId)
			lenis.destroy()
		}
	}, [])

	return null
}
