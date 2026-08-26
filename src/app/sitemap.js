import { SITE_URL } from '@/app/seo-config'

export default function sitemap() {
	const lastModified = new Date()

	return [
		{ url: SITE_URL, lastModified, changeFrequency: 'monthly', priority: 1 },
		{ url: `${SITE_URL}/telemetry`, lastModified, changeFrequency: 'daily', priority: 0.5 },
	]
}
