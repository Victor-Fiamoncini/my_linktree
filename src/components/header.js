import Link from 'next/link'

const NAV_LINKS = [
	{ label: 'Portfolio', href: '/' },
	{ label: 'Agentic Telemetry', href: '/telemetry' },
]

const Header = () => (
	<header className="sticky top-0 z-50 w-full border-b-4 border-black bg-white shadow-[0px_4px_0px_0px_#60a5fa]">
		<nav className="mx-auto flex max-w-3xl flex-col items-center gap-y-2 px-4 py-3 md:flex-row md:items-center md:justify-between">
			<Link href="/" className="text-center text-2xl font-black uppercase transition-colors hover:text-blue-400">
				Victor Fiamoncini
			</Link>

			<ul className="flex flex-wrap gap-x-4 gap-y-3 max-[425px]:w-full max-[425px]:justify-center sm:gap-x-6 md:-mt-[6px]">
				{NAV_LINKS.map(({ label, href }) => (
					<li key={href}>
						<Link
							href={href}
							className="border-b-4 border-black pb-1 text-sm font-black tracking-widest uppercase transition-all hover:border-blue-400"
						>
							{label}
						</Link>
					</li>
				))}
			</ul>
		</nav>
	</header>
)

export default Header
