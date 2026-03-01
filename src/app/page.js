import Image from 'next/image'
import { FaLinkedin, FaGithub, FaInstagram } from 'react-icons/fa'

import ContactForm from '@/components/contact-form'
import ExternalLink from '@/components/external-link'
import { GetXpYearsUseCase } from '@/core/application/use-cases/get-xp-years-use-case'

const BrandSection = () => {
	const getXpYearsUseCase = new GetXpYearsUseCase()
	const brandingText = `I've been working since ${getXpYearsUseCase.startYearOfWork} on both company and freelance projects. Currently, I focus on back-end development using PHP (Laravel/Symfony) and Node.js, while also building personal projects with Next.js`

	return (
		<section className="w-full max-w-lg border-4 border-black bg-white p-8 text-center shadow-[6px_6px_0px_0px_#60a5fa]">
			<a
				className="mb-8 inline-block border-4 border-black shadow-[4px_4px_0px_0px_#60a5fa] transition-all duration-150 hover:translate-x-[4px] hover:translate-y-[4px] hover:shadow-none"
				href="https://www.linkedin.com/in/victor-fiamoncini-b74b72159"
				target="_blank"
				rel="noopener noreferrer"
				title="Linkedin"
			>
				<Image
					className="block h-40 w-40 object-cover object-center"
					src="/photo.jpg"
					alt="Victor Fiamoncini Foto"
					width={300}
					height={300}
				/>
			</a>

			<div className="mb-6 text-2xl font-bold text-black sm:text-4xl">
				<h1 className="inline-block">Victor Fiamoncini 👨‍💻</h1>
			</div>

			<p className="mb-4 text-xl font-semibold text-gray-900">Hey 👋 What&#39;s up?</p>

			<p className="mx-auto w-full max-w-96 font-semibold text-gray-700">{brandingText}</p>
		</section>
	)
}

const ContactLinksSection = () => (
	<section className="text-center">
		<ul className="flex flex-row justify-center gap-4 align-middle">
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
	<section className="w-full max-w-lg text-center">
		<div className="border-4 border-black bg-white p-8 shadow-[6px_6px_0px_0px_#60a5fa]">
			<h2 className="mb-6 text-2xl font-bold tracking-widest text-black uppercase sm:text-3xl">Reach Out 📫</h2>

			<ContactForm />
		</div>
	</section>
)

const HomePage = () => (
	<main className="flex flex-col items-center justify-center gap-12 px-4 py-10">
		<BrandSection />

		<ContactLinksSection />

		<ContactFormSection />
	</main>
)

export default HomePage
