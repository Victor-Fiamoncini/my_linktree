'use client'

import { usePathname } from 'next/navigation'

import { getLenis, HEADER_SCROLL_OFFSET } from '@/components/smooth-scroll'

export default function GetInTouchButton() {
	const pathname = usePathname()

	const handleClick = event => {
		const lenis = getLenis()

		if (pathname !== '/' || !lenis) return

		event.preventDefault()

		lenis.scrollTo('#contact', { offset: HEADER_SCROLL_OFFSET })
	}

	return (
		<a
			href="#contact"
			onClick={handleClick}
			className="bg-ctp-blue text-ctp-crust rounded-btn hover:bg-ctp-lavender px-[22px] py-3 text-[15px] font-semibold transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[0_0_24px_-6px_var(--color-ctp-lavender)] max-[531px]:flex max-[531px]:w-full max-[531px]:items-center max-[531px]:justify-center"
		>
			Get in touch
		</a>
	)
}
