import { Geist, Geist_Mono } from 'next/font/google'

import '@/app/globals.css'
import GetYearsOfXpUseCase from '@/use-cases/GetYearsOfXpUseCase'

const getYearsOfXpUseCase = new GetYearsOfXpUseCase()
const description = `Software Engineer with ${getYearsOfXpUseCase.execute()} years of experience in both companies and freelance projects. Currently focused on back-end development using PHP (Laravel/Symfony) and NodeJS, while also building personal projects with React and Next.js.`

const geistSans = Geist({
	variable: '--font-geist-sans',
	subsets: ['latin'],
})

const geistMono = Geist_Mono({
	variable: '--font-geist-mono',
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
	metadataBase: new URL('https://victorfiamon.com.br'),
	authors: [{ name: 'Victor Fiamoncini', url: 'https://victorfiamon.com.br' }],
	creator: 'Victor Fiamoncini',
	publisher: 'Victor Fiamoncini',
	icons: {
		icon: '/favicon.ico',
		shortcut: '/icon.png',
		apple: '/apple-icon.png',
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
		url: 'https://victorfiamon.com.br',
		siteName: 'Victor Fiamoncini',
		title: 'Victor Fiamoncini',
		description,
		images: [
			{
				url: 'https://victorfiamon.com.br/photo.jpg',
				width: 1200,
				height: 630,
				alt: "Victor's photo",
			},
		],
	},
	twitter: {
		card: 'summary_large_image',
		title: 'Victor Fiamoncini',
		description,
		images: ['https://victorfiamon.com.br/photo.jpg'],
	},
	other: {
		'X-UA-Compatible': 'ie=edge',
		'msapplication-navbutton-color': '#60a5fa',
		'apple-mobile-web-app-status-bar-style': '#60a5fa',
	},
	manifest: '/site.webmanifest',
}

export const viewport = {
	width: 'device-width',
	initialScale: 1,
	maximumScale: 1,
	themeColor: '#60a5fa',
}

export default function RootLayout({ children }) {
	return (
		<html lang="en">
			<body className={`${geistSans.variable} ${geistMono.variable} antialiased bg-gray-900`}>{children}</body>
		</html>
	)
}
