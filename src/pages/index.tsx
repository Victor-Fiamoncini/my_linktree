import React from 'react'
import Head from 'next/head'

import photo from '../assets/photo.jpg'

const Home: React.FC = () => (
	<>
		<Head>
			<meta
				name="keywords"
				content="Victor, Fiamoncini, Victor Fiamoncini, Fullstack, Developer, Freelancer"
			/>
			<meta
				name="description"
				content="Victor Fiamoncini, fullstack developer/freelancer"
			/>
			<title>Victor Fiamoncini</title>
		</Head>
		<main>
			<div className="container">
				<section className="text-center">
					<img
						src={photo}
						alt="Victor Fiamoncini Foto"
						title="Victor Fiamoncini"
						className="inline-block mb-8 rounded-4xl w-32 border-4 border-blue-400"
					/>
					<h1 className="mb-4 text-gray-100 font-bold text-4xl">
						<span className="text-blue-400">&lt;</span>
						Victor Fiamoncini
						<span className="text-blue-400">&nbsp;/&gt;</span>
					</h1>
					<p className="text-gray-100 font-semibold">
						Hi there! I'm a fullstack developer/freelancer working
					</p>
				</section>
			</div>
		</main>
	</>
)

export default Home
