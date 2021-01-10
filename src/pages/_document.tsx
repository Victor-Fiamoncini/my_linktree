import React from 'react'
import Document, {
	DocumentContext,
	Html,
	Head,
	Main,
	NextScript,
} from 'next/document'

// import favicon from '../assets/favicon.png'

export default class MyDocument extends Document {
	public static async getInitialProps(ctx: DocumentContext) {
		const initialProps = await Document.getInitialProps(ctx)

		return { ...initialProps }
	}

	public render() {
		return (
			<Html lang="en">
				<Head>
					<meta httpEquiv="Content-Type" content="text/html;charset=UTF-8" />
					<meta httpEquiv="X-UA-Compatible" content="IE=7" />
					<meta httpEquiv="X-UA-Compatible" content="ie=edge" />
					<meta name="theme-color" content="#000000" />
					<meta name="msapplication-navbutton-color" content="#000000" />
					<meta
						name="apple-mobile-web-app-status-bar-style"
						content="#000000"
					/>
				</Head>
				<body className="bg-gray-900">
					<Main />
					<NextScript />
				</body>
			</Html>
		)
	}
}