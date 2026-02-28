import Image from 'next/image'
import { FaLinkedin, FaGithub, FaInstagram } from 'react-icons/fa'

import ContactForm from '@/components/contact-form'
import ExternalLink from '@/components/external-link'
import { GetXpYearsUseCase } from '@/core/application/use-cases/get-xp-years-use-case'

const BrandSection = () => {
	const getXpYearsUseCase = new GetXpYearsUseCase()
	const brandingText = `I've been working since ${getXpYearsUseCase.startYearOfWork} on both company and freelance projects. Currently, I focus on back-end development using PHP (Laravel/Symfony) and Node.js, while also building personal projects with Next.js`

	return (
		<section className="text-center bg-white border-4 border-black shadow-[6px_6px_0px_0px_#60a5fa] p-8 w-full max-w-lg">
			<a
				className="inline-block mb-8 border-4 border-black shadow-[4px_4px_0px_0px_#60a5fa] transition-all duration-150 hover:translate-x-[4px] hover:translate-y-[4px] hover:shadow-none"
				href="https://www.linkedin.com/in/victor-fiamoncini-b74b72159"
				target="_blank"
				rel="noopener noreferrer"
				title="Linkedin"
			>
				<Image
					className="block w-40 h-40 object-center object-cover"
					src="/photo.jpg"
					alt="Victor Fiamoncini Foto"
					width={300}
					height={300}
				/>
			</a>

			<div className="mb-6 text-black font-bold text-2xl sm:text-4xl">
				<h1 className="inline-block">Victor Fiamoncini 👨‍💻</h1>
			</div>

			<p className="text-gray-900 text-xl font-semibold mb-4">Hey 👋 What&#39;s up?</p>

			<p className="text-gray-700 font-semibold w-full max-w-96 mx-auto">{brandingText}</p>
		</section>
	)
}

const ContactLinksSection = () => (
	<section className="text-center">
		<ul className="flex flex-row justify-center align-middle gap-4">
			<li title="Linkedin">
				<ExternalLink link="https://www.linkedin.com/in/victor-fiamoncini-b74b72159" icon={FaLinkedin} />
			</li>

			<li title="Github">
				<ExternalLink link="https://github.com/Victor-Fiamoncini" icon={FaGithub} />
			</li>

			<li title="Instagram">
				<ExternalLink link="https://www.instagram.com/victorfiamon" icon={FaInstagram} />
			</li>
		</ul>
	</section>
)

const ContactFormSection = () => (
	<section className="text-center w-full max-w-lg">
		<div className="bg-white border-4 border-black shadow-[6px_6px_0px_0px_#60a5fa] p-8">
			<h2 className="mb-6 text-black font-bold text-2xl sm:text-3xl uppercase tracking-widest">Reach Out 📫</h2>

			<ContactForm />
		</div>
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
