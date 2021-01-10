import React from 'react'
import Head from 'next/head'
import { FaLinkedin, FaGithub, FaInstagram } from 'react-icons/fa'

import photo from '../assets/photo.jpg'
import ExternalLink from '../components/external_link'

const Home: React.FC = () => (
	<>
		<Head>
			<meta
				name="keywords"
				content="Victor, Fiamoncini, Victor Fiamoncini, Fullstack, Developer, Freelancer, ReactJS, NodeJS, PHP"
			/>
			<meta
				name="description"
				content="I'm a fullstack developer/freelancer, working mainly with ReactJS, NodeJS, PHP..."
			/>
			<title>Victor Fiamoncini</title>
		</Head>
		<main>
			<div className="container">
				<section className="text-center mb-10">
					<img
						src={photo}
						alt="Victor Fiamoncini Foto"
						title="Victor Fiamoncini"
						className="inline-block mb-8 rounded-4xl w-32 border-4 border-blue-400"
					/>
					<h1 className="mb-6 text-gray-100 font-bold text-2xl sm:text-4xl">
						<span className="text-blue-400">&lt;</span>
						Victor Fiamoncini
						<span className="text-blue-400">&nbsp;/&gt;</span>
					</h1>
					<p className="text-gray-100 font-semibold">
						Hi there! I'm a fullstack developer/freelancer
					</p>
					<p className="text-gray-100 font-semibold">
						Working mainly with <span className="text-blue-400">ReactJS</span>,{' '}
						<span className="text-green-500">NodeJS</span>,{' '}
						<span className="text-blue-600">PHP</span>...
					</p>
				</section>
				<section>
					<ul className="flex flex-row justify-center align-middle">
						<li className="mr-6" title="Linkedin">
							<ExternalLink
								link="https://www.linkedin.com/in/victor-fiamoncini-b74b72159"
								icon={FaLinkedin}
							/>
						</li>
						<li className="mr-6" title="Github">
							<ExternalLink
								link="https://github.com/Victor-Fiamoncini"
								icon={FaGithub}
							/>
						</li>
						<li title="Instagram">
							<ExternalLink
								link="https://www.instagram.com/victorfiamon"
								icon={FaInstagram}
							/>
						</li>
					</ul>
				</section>
			</div>
		</main>
	</>
)

export default Home
