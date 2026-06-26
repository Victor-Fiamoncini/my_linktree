import React from 'react'

const ExternalLink = ({ icon: Icon, link, label }) => (
	<a
		className="flex w-full items-center justify-center gap-3 border-4 border-black bg-blue-400 px-5 py-4 shadow-[4px_4px_0px_0px_#000000] transition-all duration-150 hover:translate-x-[4px] hover:translate-y-[4px] hover:shadow-none"
		href={link}
		target="_blank"
		rel="noopener noreferrer"
	>
		<span className="text-black">
			<Icon size={28} />
		</span>
		{label && <span className="text-sm font-bold tracking-widest text-black uppercase">{label}</span>}
	</a>
)

export default ExternalLink
