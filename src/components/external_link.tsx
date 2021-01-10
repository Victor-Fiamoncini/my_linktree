import React from 'react'
import { IconBaseProps } from 'react-icons'

interface IExternalLinkProps {
	icon: React.ComponentType<IconBaseProps>
	link: string
}

const ExternalLink: React.FC<IExternalLinkProps> = ({ icon: Icon, link }) => (
	<a
		href={link}
		target="_blank"
		className="block bg-gray-600 p-4 rounded-3xl border-4 border-blue-400 transform transition-all hover:-translate-y-1 hover:border-gray-100"
	>
		<span className="text-gray-100 font-semibold">
			<Icon size={32} />
		</span>
	</a>
)

export default ExternalLink
