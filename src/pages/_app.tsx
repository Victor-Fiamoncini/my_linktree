import React from 'react'
import { AppProps } from 'next/app'
import 'tailwindcss/tailwind.css'

const MyApp: React.FC<AppProps> = ({ Component, pageProps }) => (
	<div className="container m-auto py-6">
		<Component {...pageProps} />
	</div>
)

export default MyApp
