'use client'

import { useState } from 'react'
import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { FaBars, FaTimes } from 'react-icons/fa'

import { getLenis, HEADER_SCROLL_OFFSET } from '@/components/smooth-scroll'

const SECTION_LINKS = [
	{ label: '#about', href: '/#about' },
	{ label: '#experience', href: '/#experience' },
	{ label: '#hire-me', href: '/#agents' },
	{ label: '#contact', href: '/#contact' },
]

const NAV_LINK_CLASS_NAME =
	'text-ctp-subtext0 hover:text-ctp-blue relative pb-0.5 transition-colors after:absolute after:bottom-0 after:left-0 after:h-px after:w-0 after:bg-ctp-blue after:transition-all after:duration-300 hover:after:w-full'

const TELEMETRY_BUTTON_CLASS_NAME =
	'bg-ctp-green text-ctp-crust rounded-btn hover:bg-ctp-teal inline-flex items-center gap-1 px-4 py-2 transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[0_0_20px_-4px_var(--color-ctp-green)]'

const Header = () => {
	const pathname = usePathname()
	const [isMenuOpen, setIsMenuOpen] = useState(false)

	const handleAnchorClick = href => event => {
		setIsMenuOpen(false)

		const [path, hash] = href.split('#')
		const lenis = getLenis()

		if (!hash || pathname !== '/' || (path && path !== '/') || !lenis) return

		event.preventDefault()

		lenis.scrollTo(`#${hash}`, { offset: HEADER_SCROLL_OFFSET })
	}

	return (
		<header className="border-ctp-surface0 bg-ctp-mantle/86 sticky top-0 z-20 w-full border-b backdrop-blur-md">
			<nav className="mx-auto flex max-w-[1080px] items-center justify-between gap-4 px-6 py-[18px] min-[900px]:px-8">
				<Link href="/" className="flex items-center gap-3">
					<span className="bg-ctp-blue text-ctp-crust rounded-chip flex h-[26px] w-[26px] items-center justify-center font-mono text-xs font-bold">
						vf
					</span>

					<span className="text-ctp-text text-base font-semibold">Victor Fiamoncini</span>
				</Link>

				<ul className="hidden items-center gap-x-7 font-mono text-[13px] min-[900px]:flex">
					{SECTION_LINKS.map(({ label, href }) => (
						<li key={href}>
							<Link href={href} onClick={handleAnchorClick(href)} className={NAV_LINK_CLASS_NAME}>
								{label}
							</Link>
						</li>
					))}

					<li>
						<Link href="/telemetry" className={TELEMETRY_BUTTON_CLASS_NAME}>
							/telemetry <span className="text-ctp-crust/70">↗</span>
						</Link>
					</li>
				</ul>

				<button
					type="button"
					onClick={() => setIsMenuOpen(open => !open)}
					aria-expanded={isMenuOpen}
					aria-label="Toggle navigation menu"
					className="border-ctp-surface1 text-ctp-text rounded-btn hover:border-ctp-blue flex h-9 w-9 cursor-pointer items-center justify-center border transition-all duration-200 hover:scale-105 min-[900px]:hidden"
				>
					{isMenuOpen ? <FaTimes size={16} /> : <FaBars size={16} />}
				</button>
			</nav>

			{isMenuOpen && (
				<div className="border-ctp-surface0 bg-ctp-mantle border-t px-6 py-5 min-[900px]:hidden">
					<ul className="flex flex-col items-start gap-4 font-mono text-[13px]">
						{SECTION_LINKS.map(({ label, href }) => (
							<li key={href}>
								<Link href={href} onClick={handleAnchorClick(href)} className={NAV_LINK_CLASS_NAME}>
									{label}
								</Link>
							</li>
						))}

						<li>
							<Link href="/telemetry" onClick={() => setIsMenuOpen(false)} className={TELEMETRY_BUTTON_CLASS_NAME}>
								/telemetry <span className="text-ctp-crust/70">↗</span>
							</Link>
						</li>
					</ul>
				</div>
			)}
		</header>
	)
}

export default Header
