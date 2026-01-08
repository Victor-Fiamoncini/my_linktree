import React from 'react'

const ExternalLink = ({ icon: Icon, link }) => (
	<a
		className="block bg-gray-600 p-4 rounded-3xl border-4 border-blue-400 transform transition-all hover:-translate-y-0.5 hover:border-gray-100"
		href={link}
		target="_blank"
		rel="noopener noreferrer"
	>
		<span className="text-gray-100">
			<Icon size={32} />
		</span>
	</a>
)

export default ExternalLink
