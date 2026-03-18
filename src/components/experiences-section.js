'use client'

import { useState } from 'react'

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

const formatDate = dateStr => {
	if (!dateStr) return 'Present'

	const [year, month] = dateStr.split('-')

	return `${MONTH_NAMES[parseInt(month, 10) - 1]} ${year}`
}

const TechBadge = ({ tech }) => (
	<span className="border-2 border-black bg-blue-400 px-2 py-1 text-xs font-bold text-black shadow-[2px_2px_0px_0px_#000]">
		{tech}
	</span>
)

const ExperienceEntry = ({ experience }) => (
	<div className="mb-4 last:mb-0">
		<p className="text-lg font-bold text-black">{experience.role}</p>

		<p className="mb-1 text-sm font-semibold text-gray-600">
			{formatDate(experience.startDate)} — {formatDate(experience.endDate)}

			<span className="ml-2 text-gray-400">({experience.durationLabel})</span>
		</p>

		<p className="mb-3 text-sm text-gray-500">{experience.location}</p>

		<p className="mb-2 text-xs font-bold tracking-widest text-gray-500 uppercase">Technologies used</p>

		<div className="flex flex-wrap gap-2">
			{experience.stack.map(tech => (
				<TechBadge key={tech} tech={tech} />
			))}
		</div>
	</div>
)

const ExperiencesSection = ({ experiences }) => {
	const companies = experiences.reduce((acc, exp) => {
		const existing = acc.find(g => g.company === exp.company)

		if (existing) {
			existing.entries.push(exp)
		} else {
			acc.push({ company: exp.company, entries: [exp] })
		}

		return acc
	}, [])

	const [activeTab, setActiveTab] = useState(companies[0]?.company ?? '')

	const activeCompany = companies.find(g => g.company === activeTab)

	return (
		<section className="w-full max-w-lg">
			<div className="border-4 border-black bg-white shadow-[6px_6px_0px_0px_#60a5fa]">
				<div className="border-b-4 border-black">
					<h2 className="mb-6 flex items-center justify-center gap-2 px-8 pt-8 text-2xl font-bold tracking-widest text-black uppercase sm:text-3xl">
						<span>Experience</span>

						<span className="translate-y-0.5">💼</span>
					</h2>

					<div className="flex">
						{companies.map(group => (
							<button
								key={group.company}
								onClick={() => setActiveTab(group.company)}
								className={`flex-1 cursor-pointer border-t-2 border-r-2 border-black px-4 py-2 text-sm font-bold transition-colors duration-100 last:border-r-0 ${
									activeTab === group.company ? 'bg-black text-white' : 'bg-gray-100 text-black hover:bg-gray-200'
								}`}
							>
								{group.company}
							</button>
						))}
					</div>
				</div>

				<div className="p-8">
					{activeCompany?.entries.map((exp, idx) => (
						<div key={exp.id}>
							{idx > 0 && <hr className="my-4 border-t-2 border-dashed border-gray-300" />}

							<ExperienceEntry experience={exp} />
						</div>
					))}
				</div>
			</div>
		</section>
	)
}

export default ExperiencesSection
