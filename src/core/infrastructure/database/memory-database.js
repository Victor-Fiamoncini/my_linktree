export class MemoryDatabase {
	#profile

	constructor() {
		this.#profile = {
			name: 'Victor Fiamoncini',
			headline: 'Software Engineer | PHP | Laravel | Next.js @Breaker19',
			location: 'Rodeio, Santa Catarina, Brazil',
			contact: {
				phone: '+55 988897443',
				email: 'victor.fiamoncini@gmail.com',
				linkedin: 'https://www.linkedin.com/in/victorfiamoncini-b74b72159',
				website: 'https://www.victorfiamon.com.br',
			},
			summary:
				"I've been working since 2019 on both company and freelance projects. Currently, I focus on back-end development using PHP (Laravel/Symfony) and Node.js, while also building personal projects with Next.js.",
			skills: ['Object-oriented Design', 'Next.js', 'AWS'],
			certifications: [
				'Natural Language Part 1: NLP with Sentiment Analysis',
				'Flutter, TDD, Clean Architecture, SOLID and Design Patterns',
				'Machine Learning: Classification with SKLearn',
				'Machine Learning: Advancing with Different Types of Classification',
				'MERN Stack Front To Back: Full Stack React, Redux & Node.js',
			],
			experiences: [
				{
					id: 1,
					company: 'Breaker19',
					role: 'Fullstack Software Engineer',
					stack: ['PHP', 'Laravel', 'React'],
					location: 'Rodeio, Santa Catarina, Brazil',
					startDate: '2024-12',
					endDate: null,
					current: true,
					durationLabel: '1 year 4 months',
					description: null,
				},
				{
					id: 2,
					company: 'Rede Vistorias',
					role: 'Fullstack Software Engineer',
					stack: ['PHP', 'Python', 'React'],
					location: 'Rodeio, Santa Catarina, Brazil',
					startDate: '2021-01',
					endDate: '2024-12',
					current: false,
					durationLabel: '4 years',
					description: null,
				},
				{
					id: 3,
					company: 'Vexta',
					role: 'Backend Software Engineer',
					stack: ['Node.js'],
					location: 'Rio do Sul, Santa Catarina, Brazil',
					startDate: '2020-07',
					endDate: '2021-01',
					current: false,
					durationLabel: '7 months',
					description: null,
				},
				{
					id: 4,
					company: 'Área Local',
					role: 'Fullstack Web Developer',
					stack: ['PHP', 'JavaScript'],
					location: 'Rio do Sul, Santa Catarina, Brazil',
					startDate: '2019-02',
					endDate: '2020-06',
					current: false,
					durationLabel: '1 year 5 months',
					description: null,
				},
				{
					id: 5,
					company: 'Área Local',
					role: 'Internship in Web Development',
					stack: ['PHP', 'JavaScript'],
					location: 'Rio do Sul, Santa Catarina, Brazil',
					startDate: '2018-10',
					endDate: '2019-01',
					current: false,
					durationLabel: '4 months',
					description: null,
				},
			],
			education: [
				{
					id: 1,
					institution: 'Instituto Federal Catarinense',
					degree: 'Bachelor',
					field: 'Computer Science',
					startDate: '2017-02',
					endDate: '2024-04',
					current: false,
				},
				{
					id: 2,
					institution: 'Instituto Federal Catarinense',
					degree: 'Technical Agriculture',
					field: 'Complete Technical High School',
					startDate: '2012-01',
					endDate: '2014-12',
					current: false,
				},
			],
		}
	}

	async getProfile() {
		return this.#profile
	}
}
