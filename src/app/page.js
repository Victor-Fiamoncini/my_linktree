import Image from 'next/image'
import { FaLinkedin, FaGithub } from 'react-icons/fa'

import ContactForm from '@/components/contact-form'
import ExternalLink from '@/components/external-link'
import ExperiencesSection from '@/components/experiences-section'
import GetInTouchButton from '@/components/get-in-touch-button'
import HireFromAgent from '@/components/hire-from-agent'
import { GetXpYearsUseCase } from '@/core/application/use-cases/get-xp-years-use-case'
import { GetProfileUseCase } from '@/core/application/use-cases/get-profile-use-case'
import { MemoryDatabase } from '@/core/infrastructure/database/memory-database'

const GITHUB_LINK = 'https://github.com/Victor-Fiamoncini'
const LINKEDIN_LINK = 'https://www.linkedin.com/in/victor-fiamoncini-b74b72159'

const SWATCH_CLASS_NAMES = [
	'bg-ctp-blue',
	'bg-ctp-mauve',
	'bg-ctp-green',
	'bg-ctp-yellow',
	'bg-ctp-peach',
	'bg-ctp-teal',
]

const HeroSection = () => {
	const getXpYearsUseCase = new GetXpYearsUseCase()

	return (
		<section
			id="about"
			className="grid w-full max-w-[1080px] items-center gap-12 pt-16 pb-14 min-[900px]:grid-cols-[1fr_260px] min-[900px]:gap-16 min-[900px]:pt-24"
		>
			<div>
				<p className="text-ctp-green mb-5 font-mono text-[13px] tracking-[0.06em]">$ whoami</p>

				<h1 className="text-ctp-text mb-6 text-[40px] leading-[1.04] font-bold tracking-[-0.035em] min-[900px]:text-[58px]">
					Victor <span className="text-ctp-mauve">Fiamoncini</span>
				</h1>

				<p className="text-ctp-subtext1 mb-[18px] max-w-[46ch] text-[19px] leading-[1.6] text-pretty">
					Software Engineer since {getXpYearsUseCase.startYearOfWork}, across company and freelance projects.
				</p>

				<p className="text-ctp-subtext0 mb-9 max-w-[52ch] text-[17px] leading-[1.7] text-pretty">
					Currently focused on back-end development using PHP (Laravel/Symfony), while also building personal projects
					with Ruby on Rails and Next.js.
				</p>

				<div className="flex flex-wrap gap-3">
					<GetInTouchButton />

					<ExternalLink link={GITHUB_LINK} icon={FaGithub} label="GitHub" />

					<ExternalLink link={LINKEDIN_LINK} icon={FaLinkedin} label="LinkedIn" />
				</div>
			</div>

			<div className="relative order-first justify-self-center min-[900px]:order-none min-[900px]:justify-self-end">
				<div className="absolute -inset-2.5 rounded-[10px] bg-[linear-gradient(150deg,var(--color-ctp-blue),var(--color-ctp-mauve)_55%,var(--color-ctp-green))] opacity-50" />

				<Image
					className="border-ctp-surface1 rounded-card relative block h-[300px] w-[260px] border object-cover"
					src="/photo.jpg"
					alt="Victor Fiamoncini"
					width={260}
					height={300}
				/>
			</div>
		</section>
	)
}

const ContactAside = () => (
	<div className="grid gap-3">
		<ExternalLink
			variant="card"
			accent="blue"
			icon={FaLinkedin}
			label="LinkedIn"
			handle="/in/victor-fiamoncini"
			link={LINKEDIN_LINK}
		/>

		<ExternalLink
			variant="card"
			accent="mauve"
			icon={FaGithub}
			label="GitHub"
			handle="Victor-Fiamoncini"
			link={GITHUB_LINK}
		/>

		<div className="bg-ctp-mantle border-ctp-surface0 rounded-btn border px-5 py-[18px]">
			<p className="text-ctp-overlay0 mb-2 font-mono text-xs tracking-[0.08em] uppercase">Theme</p>

			<p className="text-ctp-subtext0 mb-3.5 text-sm">Catppuccin Frappé</p>

			<div className="flex gap-1.5">
				{SWATCH_CLASS_NAMES.map(className => (
					<span key={className} className={`rounded-chip h-5 w-5 ${className}`} />
				))}
			</div>
		</div>
	</div>
)

const ContactFormSection = () => (
	<section id="contact" className="border-ctp-surface0 w-full max-w-[1080px] border-t pt-14 pb-14">
		<p className="text-ctp-teal mb-3.5 font-mono text-[13px] tracking-[0.06em]">$ echo &quot;let&#39;s talk&quot;</p>

		<h2 className="text-ctp-text mb-4 text-[28px] font-semibold tracking-[-0.025em] min-[900px]:text-[34px]">
			Reach out
		</h2>

		<p className="text-ctp-subtext0 mb-10 max-w-[58ch] text-[17px] leading-[1.7] text-pretty">
			Working on something interesting? I&#39;m always open to remote roles, freelance work, and fullstack
			collaboration. If you have a project in mind, let&#39;s talk.
		</p>

		<div className="grid gap-12 min-[900px]:grid-cols-[1.2fr_1fr] min-[900px]:items-start">
			<ContactForm />

			<ContactAside />
		</div>
	</section>
)

const HomePage = async () => {
	const getProfileUseCase = new GetProfileUseCase({ database: new MemoryDatabase() })
	const profile = await getProfileUseCase.execute()

	return (
		<main className="flex flex-1 flex-col items-center px-8">
			<HeroSection />

			<ExperiencesSection experiences={profile.experiences} />

			<HireFromAgent />

			<ContactFormSection />
		</main>
	)
}

export default HomePage
