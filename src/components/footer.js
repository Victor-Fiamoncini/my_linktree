const Footer = () => (
	<footer className="border-ctp-surface0 bg-ctp-mantle w-full border-t">
		<div className="text-ctp-overlay0 mx-auto flex max-w-[1080px] flex-wrap items-center justify-between gap-3 px-8 py-7 font-mono text-xs max-[424px]:flex-col max-[424px]:justify-center max-[424px]:text-center">
			<span>© {new Date().getFullYear()} Victor Fiamoncini</span>

			<span>
				built with{' '}
				<a
					href="https://catppuccin.com/"
					target="_blank"
					rel="noreferrer"
					className="text-ctp-mauve hover:text-ctp-pink"
				>
					catppuccin
				</a>
			</span>
		</div>
	</footer>
)

export default Footer
