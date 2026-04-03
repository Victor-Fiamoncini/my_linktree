const NAV_LINKS = [
	{ label: 'About', href: '#' },
	{ label: 'Experience', href: '#experience' },
	{ label: 'Contact', href: '#contact' },
]

const Header = () => (
	<header className="sticky top-0 z-50 w-full border-b-4 border-black bg-white shadow-[0px_4px_0px_0px_#60a5fa]">
		<nav className="mx-auto flex max-w-3xl flex-col items-center gap-y-2 py-3 md:flex-row md:justify-between">
			<a href="#" className="text-2xl font-black uppercase transition-colors hover:text-blue-400">
				Victor Fiamoncini
			</a>

			<ul className="flex flex-wrap gap-x-4 sm:gap-x-6">
				{NAV_LINKS.map(({ label, href }) => (
					<li key={href}>
						<a
							href={href}
							className="border-b-4 border-black pb-1 text-sm font-black tracking-widest uppercase transition-all hover:border-blue-400"
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
