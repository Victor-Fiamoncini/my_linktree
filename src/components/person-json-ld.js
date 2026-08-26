import { AUTHOR_NAME, GITHUB_URL, JOB_TITLE, LINKEDIN_URL, SITE_NAME, SITE_URL } from '@/app/seo-config'

const jsonLd = {
	'@context': 'https://schema.org',
	'@graph': [
		{
			'@type': 'Person',
			'@id': `${SITE_URL}/#person`,
			name: AUTHOR_NAME,
			url: SITE_URL,
			image: `${SITE_URL}/photo.jpg`,
			jobTitle: JOB_TITLE,
			sameAs: [LINKEDIN_URL, GITHUB_URL],
		},
		{
			'@type': 'WebSite',
			'@id': `${SITE_URL}/#website`,
			name: SITE_NAME,
			url: SITE_URL,
			author: { '@id': `${SITE_URL}/#person` },
		},
	],
}

const PersonJsonLd = () => (
	<script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }} />
)

export default PersonJsonLd
