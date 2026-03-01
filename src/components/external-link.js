import React from 'react'

const ExternalLink = ({ icon: Icon, link }) => (
	<a
		className="block border-4 border-black bg-blue-400 p-4 shadow-[4px_4px_0px_0px_#000000] transition-all duration-150 hover:translate-x-[4px] hover:translate-y-[4px] hover:shadow-none"
		href={link}
		target="_blank"
		rel="noopener noreferrer"
	>
		<span className="text-black">
			<Icon size={32} />
		</span>
	</a>
)

export default ExternalLink
