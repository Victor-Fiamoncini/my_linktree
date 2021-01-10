import React from 'react'
import { AppProps } from 'next/app'
import 'tailwindcss/tailwind.css'

const MyApp: React.FC<AppProps> = ({ Component, pageProps }) => (
	<div className="container m-auto p-4 sm:p-6">
		<Component {...pageProps} />
	</div>
)

export default MyApp
