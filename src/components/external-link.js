import React from 'react'

const CARD_HOVER_CLASSES = {
	blue: 'hover:border-ctp-blue hover:shadow-[0_0_20px_-8px_var(--color-ctp-blue)]',
	mauve: 'hover:border-ctp-mauve hover:shadow-[0_0_20px_-8px_var(--color-ctp-mauve)]',
}

const CARD_ICON_CLASSES = {
	blue: 'text-ctp-blue',
	mauve: 'text-ctp-mauve',
}

const ExternalLink = ({ icon: Icon, link, label, variant = 'outline', handle, accent = 'blue' }) => {
	if (variant === 'card') {
		return (
			<a
				className={`bg-ctp-mantle border-ctp-surface0 rounded-btn flex items-center justify-between gap-3 border px-5 py-[18px] transition-all duration-200 hover:-translate-y-0.5 ${CARD_HOVER_CLASSES[accent]}`}
				href={link}
				target="_blank"
				rel="noopener noreferrer"
			>
				<span className="flex items-center gap-3">
					<span className={CARD_ICON_CLASSES[accent]}>
						<Icon size={18} />
					</span>

					{label && <span className="text-ctp-text text-sm font-medium">{label}</span>}
				</span>

				{handle && <span className="text-ctp-overlay0 font-mono text-xs">{handle}</span>}
			</a>
		)
	}

	return (
		<a
			className="border-ctp-surface1 text-ctp-text rounded-btn hover:border-ctp-blue hover:bg-ctp-surface0 inline-flex items-center justify-center gap-[9px] border px-[22px] py-3 transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[0_0_20px_-8px_var(--color-ctp-blue)] max-[531px]:w-full"
			href={link}
			target="_blank"
			rel="noopener noreferrer"
		>
			<span className="text-current">
				<Icon size={18} />
			</span>

			{label && <span className="font-mono text-sm">{label}</span>}
		</a>
	)
}

export default ExternalLink
