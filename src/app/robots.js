import { SITE_URL } from '@/app/seo-config'

export default function robots() {
	return {
		rules: {
			userAgent: '*',
			allow: '/',
			disallow: '/api/',
		},
		sitemap: `${SITE_URL}/sitemap.xml`,
		host: SITE_URL,
	}
}
