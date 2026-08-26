import { Analytics } from '@vercel/analytics/next'
import { JetBrains_Mono, Space_Grotesk } from 'next/font/google'

import { GetXpYearsUseCase } from '@/core/application/use-cases/get-xp-years-use-case'
import Footer from '@/components/footer'
import Header from '@/components/header'
import PersonJsonLd from '@/components/person-json-ld'
import SmoothScroll from '@/components/smooth-scroll'
import { SITE_URL } from '@/app/seo-config'

import '@/app/globals.css'

const getXpYearsUseCase = new GetXpYearsUseCase()
const description = `Software Engineer with ${getXpYearsUseCase.execute()} years of experience in both companies and freelance projects. Currently focused on back-end development using PHP (Laravel/Symfony) and NodeJS, while also building personal projects with React and Next.js.`

const spaceGrotesk = Space_Grotesk({
	variable: '--font-space-grotesk',
	subsets: ['latin'],
})

const jetBrainsMono = JetBrains_Mono({
	variable: '--font-jetbrains-mono',
	subsets: ['latin'],
})

export const metadata = {
	title: 'Victor Fiamoncini',
	description,
	keywords: [
		'Victor Fiamoncini',
		'Software Developer',
		'Software Engineer',
		'Full Stack Developer',
		'Developer',
		'PHP',
		'Laravel',
		'Symfony',
		'NodeJS',
		'React',
		'Next.js',
	],
	metadataBase: new URL(SITE_URL),
	authors: [{ name: 'Victor Fiamoncini', url: SITE_URL }],
	creator: 'Victor Fiamoncini',
	publisher: 'Victor Fiamoncini',
	applicationName: 'Victor Fiamoncini',
	category: 'technology',
	alternates: {
		canonical: '/',
	},
	robots: {
		index: true,
		follow: true,
		googleBot: {
			index: true,
			follow: true,
			'max-video-preview': -1,
			'max-image-preview': 'large',
			'max-snippet': -1,
		},
	},
	openGraph: {
		type: 'website',
		locale: 'en_US',
		url: SITE_URL,
		siteName: 'Victor Fiamoncini',
		title: 'Victor Fiamoncini',
		description,
	},
	twitter: {
		card: 'summary_large_image',
		title: 'Victor Fiamoncini',
		description,
	},
	other: {
		'X-UA-Compatible': 'ie=edge',
		'msapplication-navbutton-color': '#8caaee',
		'apple-mobile-web-app-status-bar-style': '#8caaee',
	},
	manifest: '/site.webmanifest',
}

export const viewport = {
	width: 'device-width',
	initialScale: 1,
	maximumScale: 1,
	themeColor: '#8caaee',
}

export default function RootLayout({ children }) {
	return (
		<html lang="en">
			<body
				className={`${spaceGrotesk.variable} ${jetBrainsMono.variable} bg-ctp-base flex min-h-screen flex-col antialiased`}
			>
				<PersonJsonLd />

				<SmoothScroll />

				<Header />

				{children}

				<Footer />

				<Analytics />
			</body>
		</html>
	)
}
