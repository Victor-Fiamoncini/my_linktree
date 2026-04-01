export class MemoryDatabase {
	#profile

	constructor() {
		this.#profile = {
			name: 'Victor Fiamoncini',
			experiences: [
				{
					id: 1,
					company: 'Breaker19',
					role: 'Fullstack Software Engineer',
					backend: ['PHP', 'Laravel', 'Next.js', 'Postgres', 'MongoDB', 'Auth0', 'Postmark'],
					frontend: ['React', 'Vue', 'Tailwind CSS', 'SCSS', 'TypeScript', 'Cypress'],
					infra: ['AWS', 'Render Cloud', 'Docker', 'Docker Compose', 'Nginx', 'Sentry', 'LogRocket'],
					otherTools: ['Git', 'GitHub', 'Claude Code', 'Postman', 'Figma', 'Linear'],
					countryFlag: '🇺🇸',
					location: 'Rodeio, Santa Catarina, Brazil',
					startDate: '2024-12',
					endDate: null,
					current: true,
					durationLabel: '1 year 4 months',
					description:
						'Contributing to a large Laravel monolith and multiple front-end web applications that enable customers to schedule FTL and Hotshot trucking orders, connecting them with carriers and drivers. Built a new Next.js carrier app featuring real-time driver location tracking via Mapbox SDK and WebSocket-based chats. Implemented asynchronous Laravel background jobs for driver route check-in/check-out validation, set up a CI environment with Jenkins integrated with the Render Application Platform, and introduced integration testing using PHPUnit and Cypress.',
				},
				{
					id: 2,
					company: 'Rede Vistorias',
					role: 'Fullstack Software Engineer',
					backend: [
						'Python',
						'Flask',
						'PHP',
						'Laravel',
						'Symfony',
						'Postgres',
						'MongoDB',
						'Redis',
						'RabbitMQ',
						'Snowflake',
					],
					frontend: ['React', 'Twig', 'Tailwind CSS', 'SCSS', 'TypeScript', 'Cypress'],
					infra: ['AWS', 'Docker', 'Docker Compose', 'Nginx', 'Sentry', 'Elastic (ELK)'],
					otherTools: ['Git', 'Gitea', 'Postman', 'Figma', 'Jira'],
					countryFlag: '🇧🇷',
					location: 'Rodeio, Santa Catarina, Brazil',
					startDate: '2021-01',
					endDate: '2024-12',
					current: false,
					durationLabel: '4 years',
					description:
						'Built and maintained API microservices and front-end dashboards to enhance the experience of customers and franchisees managing real estate inspections. Led migrations of PHP (Symfony and Laravel) microservices to version 8 with FrankenPHP, Python (Flask) services to version 3 with Gunicorn, and React repositories to version 18 with TypeScript and Vite. Developed event-driven architectures using RabbitMQ and Redis (push/pull pattern) and implemented extensive automated testing with Cypress, Pytest, and PHPUnit.',
				},
				{
					id: 3,
					company: 'Vexta',
					role: 'Backend Software Engineer',
					backend: ['NodeJS', 'Express', 'TypeScript', 'PostgreSQL', 'MongoDB', 'Redis'],
					frontend: [],
					infra: ['Azure', 'Docker', 'Docker Compose', 'Nginx'],
					otherTools: ['Git', 'Bitbucket', 'Postman', 'Jira'],
					countryFlag: '🇧🇷',
					location: 'Rio do Sul, Santa Catarina, Brazil',
					startDate: '2020-07',
					endDate: '2021-01',
					current: false,
					durationLabel: '7 months',
					description:
						'Contributed to a new Node.js back-end focused on authentication and financial features for an existing fashion ERP system. Designed and implemented a full authentication API with PostgreSQL, integrated Redis for push/pull messaging to handle email and notification delivery, and built a private Node.js NPM logging library that centralized backend logs in MongoDB. Wrote unit tests for new services using Jest.',
				},
				{
					id: 4,
					company: 'Área Local',
					role: 'Fullstack Web Developer',
					backend: ['PHP', 'WordPress', 'Laravel', 'MySQL'],
					frontend: ['HTML', 'CSS', 'JavaScript', 'JQuery', 'SCSS', 'React'],
					infra: [],
					otherTools: ['Git', 'GitHub', 'Postman', 'Trello', 'Filezilla'],
					countryFlag: '🇧🇷',
					location: 'Rio do Sul, Santa Catarina, Brazil',
					startDate: '2019-02',
					endDate: '2020-06',
					current: false,
					durationLabel: '1 year 5 months',
					description:
						'Primarily developed websites, landing pages, and custom WordPress themes using PHP. Implemented front-end features with jQuery, SCSS, and React, and delivered small projects using Laravel. Provided customer support through client calls, production bug fixes, and resolving third-party integration issues.',
				},
				{
					id: 5,
					company: 'Área Local',
					role: 'Internship in Web Development',
					backend: [],
					frontend: [],
					infra: [],
					otherTools: [],
					countryFlag: '🇧🇷',
					location: 'Rio do Sul, Santa Catarina, Brazil',
					startDate: '2018-10',
					endDate: '2019-01',
					current: false,
					durationLabel: '4 months',
					description:
						'Completed an internship as part of my university degree, focusing on web development with PHP, WordPress, jQuery, and SCSS.',
				},
			],
			education: [
				{
					id: 1,
					institution: 'Instituto Federal Catarinense',
					degree: 'Bachelor',
					field: 'Computer Science',
				},
				{
					id: 2,
					institution: 'Instituto Federal Catarinense',
					degree: 'Technical Agriculture',
					field: 'Complete Technical High School',
				},
			],
		}
	}

	async getProfile() {
		return this.#profile
	}
}
