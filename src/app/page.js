import Image from 'next/image'
import { FaLinkedin, FaGithub, FaInstagram } from 'react-icons/fa'

import ContactForm from '@/components/contact-form'
import ExternalLink from '@/components/external-link'
import { GetXpYearsUseCase } from '@/core/application/use-cases/get-xp-years-use-case'

const BrandSection = () => {
	const getXpYearsUseCase = new GetXpYearsUseCase()
	const brandingText = `I've been working since ${getXpYearsUseCase.startYearOfWork} on both company and freelance projects. Currently, I focus on back-end development using PHP (Laravel/Symfony) and Node.js, while also building personal projects with React and Next.js`

	return (
		<section className="text-center">
			<Image
				className="inline-block mb-8 rounded-2xl w-40 h-40 object-center object-cover border-4 border-blue-400"
				src="/photo.jpg"
				alt="Victor Fiamoncini Foto"
				title="Victor Fiamoncini"
				width={300}
				height={300}
			/>

			<div className="mb-6 text-gray-100 font-bold text-2xl sm:text-4xl">
				<span className="text-blue-400">&lt;</span>

				<h1 className="inline-block">Victor Fiamoncini</h1>

				<span className="text-blue-400">&nbsp;/&gt;</span>
			</div>

			<p className="text-gray-100 font-semibold mb-4">Hey 👋 What&#39;s up?</p>

			<p className="text-gray-100 font-semibold w-full max-w-96">{brandingText}</p>
		</section>
	)
}

const ContactLinksSection = () => (
	<section className="text-center">
		<ul className="flex flex-row justify-center align-middle">
			<li className="mr-6" title="Linkedin">
				<ExternalLink link="https://www.linkedin.com/in/victor-fiamoncini-b74b72159" icon={FaLinkedin} />
			</li>

			<li className="mr-6" title="Github">
				<ExternalLink link="https://github.com/Victor-Fiamoncini" icon={FaGithub} />
			</li>

			<li title="Instagram">
				<ExternalLink link="https://www.instagram.com/victorfiamon" icon={FaInstagram} />
			</li>
		</ul>
	</section>
)

const ContactFormSection = () => (
	<section className="text-center">
		<div className="bg-white h-1 w-24 m-auto mb-10" />

		<h2 className="mb-6 text-gray-100 font-bold text-2xl sm:text-3xl">Reach Out</h2>

		<ContactForm />
	</section>
)

const HomePage = () => (
	<main className="flex flex-col justify-center items-center px-4 py-10 gap-12">
		<BrandSection />

		<ContactLinksSection />

		<ContactFormSection />
	</main>
)

export default HomePage
