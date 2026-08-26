'use client'

import { useState } from 'react'

const MONTH_NAMES = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

const formatDate = dateStr => {
	if (!dateStr) return 'Present'

	const [year, month] = dateStr.split('-')

	return `${MONTH_NAMES[parseInt(month, 10) - 1]} ${year}`
}

const calcDuration = (startDate, endDate) => {
	const [startYear, startMonth] = startDate.split('-').map(Number)
	const end = endDate ? endDate.split('-').map(Number) : [new Date().getFullYear(), new Date().getMonth() + 1]
	const [endYear, endMonth] = end

	let months = (endYear - startYear) * 12 + (endMonth - startMonth)
	const years = Math.floor(months / 12)
	months = months % 12

	const parts = []

	if (years > 0) parts.push(`${years} year${years > 1 ? 's' : ''}`)
	if (months > 0) parts.push(`${months} month${months > 1 ? 's' : ''}`)

	return parts.join(' ') || 'Less than a month'
}

const TECH_CATEGORIES = [
	{ key: 'backend', label: 'Backend', accentClassName: 'text-ctp-blue' },
	{ key: 'frontend', label: 'Frontend', accentClassName: 'text-ctp-mauve' },
	{ key: 'infra', label: 'Infra', accentClassName: 'text-ctp-green' },
	{ key: 'otherTools', label: 'Tools', accentClassName: 'text-ctp-yellow' },
]

const TAB_ACCENT_CLASS_NAMES = [
	'text-ctp-blue min-[900px]:border-ctp-blue',
	'text-ctp-mauve min-[900px]:border-ctp-mauve',
	'text-ctp-green min-[900px]:border-ctp-green',
	'text-ctp-yellow min-[900px]:border-ctp-yellow',
]

const TechChip = ({ tech }) => (
	<span className="bg-ctp-base border-ctp-surface1 text-ctp-text rounded-chip border px-3 py-1.5 font-mono text-[13px]">
		{tech}
	</span>
)

const ExperienceEntry = ({ experience }) => (
	<div>
		<div className="mb-1.5 flex flex-wrap items-baseline gap-2.5">
			<h3 className="text-ctp-text text-[23px] font-semibold">{experience.role}</h3>

			<span className="text-ctp-mauve text-[19px] font-medium">@ {experience.company}</span>
		</div>

		<p className="text-ctp-subtext0 mb-1 font-mono text-[13px]">
			{formatDate(experience.startDate)} — {formatDate(experience.endDate)}
			<span className="text-ctp-overlay0 ml-2">({calcDuration(experience.startDate, experience.endDate)})</span>
		</p>

		<p className="text-ctp-overlay0 mb-[22px] flex items-center gap-2 font-mono text-[13px]">
			<span>{experience.location}</span>

			{experience.countryFlag && <span title={experience.countryName}>{experience.countryFlag}</span>}
		</p>

		{experience.description && (
			<p className="text-ctp-subtext1 mb-7 max-w-[62ch] text-base leading-[1.75] text-pretty">
				{experience.description}
			</p>
		)}

		<div className="flex flex-col gap-[18px]">
			{TECH_CATEGORIES.filter(cat => experience[cat.key]?.length > 0).map(cat => (
				<div key={cat.key}>
					<p className={`mb-2.5 font-mono text-[11px] font-medium tracking-[0.12em] uppercase ${cat.accentClassName}`}>
						{cat.label}
					</p>

					<div className="flex flex-wrap gap-2">
						{experience[cat.key].map(tech => (
							<TechChip key={tech} tech={tech} />
						))}
					</div>
				</div>
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
		<section id="experience" className="border-ctp-surface0 w-full max-w-[1080px] border-t pt-14 pb-14">
			<p className="text-ctp-yellow mb-3.5 font-mono text-[13px] tracking-[0.06em]">$ cat career.log</p>

			<h2 className="text-ctp-text mb-10 text-[28px] font-semibold tracking-[-0.025em] min-[900px]:text-[34px]">
				Where I&#39;ve worked
			</h2>

			<div className="flex flex-col gap-8 min-[900px]:grid min-[900px]:grid-cols-[210px_1fr] min-[900px]:items-start min-[900px]:gap-10">
				<div className="border-ctp-surface0 flex gap-1 overflow-x-auto border-b pb-3 min-[900px]:flex-col min-[900px]:border-b-0 min-[900px]:border-l-2 min-[900px]:pb-0">
					{companies.map((group, index) => {
						const isActive = activeTab === group.company
						const accentClassName = TAB_ACCENT_CLASS_NAMES[index % TAB_ACCENT_CLASS_NAMES.length]

						return (
							<button
								key={group.company}
								onClick={() => setActiveTab(group.company)}
								title={group.company}
								className={`rounded-chip min-w-max cursor-pointer px-4 py-2.5 text-left font-mono text-[15px] whitespace-nowrap transition-all duration-[180ms] min-[900px]:-ml-0.5 min-[900px]:rounded-none min-[900px]:border-l-2 min-[900px]:border-transparent min-[900px]:px-4 min-[900px]:py-3 ${
									isActive ? `bg-ctp-surface0 font-semibold ${accentClassName}` : 'text-ctp-subtext0 font-normal'
								}`}
							>
								{group.company}
							</button>
						)
					})}
				</div>

				<div
					key={activeCompany?.company}
					className="bg-ctp-mantle border-ctp-surface0 rounded-card animate-[fr-fade_0.28s_ease_both] border p-8"
				>
					{activeCompany?.entries.map((exp, index) => (
						<div key={exp.id}>
							{index > 0 && <hr className="border-ctp-surface0 my-7 border-t border-dashed" />}

							<ExperienceEntry experience={exp} />
						</div>
					))}
				</div>
			</div>
		</section>
	)
}

export default ExperiencesSection
