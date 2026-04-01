'use client'

const NAV_LINKS = [
	{ label: 'About', href: '#about' },
	{ label: 'Experience', href: '#experience' },
	{ label: 'Contact', href: '#contact' },
]

const Header = () => (
	<header className="sticky top-0 z-50 w-full border-b-4 border-black bg-white shadow-[0px_4px_0px_0px_#60a5fa]">
		<nav className="mx-auto flex max-w-3xl items-center justify-between px-4 py-3">
			<a
				href="#about"
				className="text-xs font-bold tracking-wider text-black uppercase transition-colors duration-100 hover:text-blue-400 sm:text-sm sm:tracking-widest"
			>
				Victor Fiamoncini
			</a>

			<ul className="flex gap-2 sm:gap-4">
				{NAV_LINKS.map(({ label, href }) => (
					<li key={href}>
						<a
							href={href}
							className="text-xs font-bold text-black transition-colors duration-100 hover:text-blue-400 sm:text-sm"
						>
							{label}
						</a>
					</li>
				))}
			</ul>
		</nav>
	</header>
)

export default Header
