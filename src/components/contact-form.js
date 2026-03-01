'use client'

import { useState } from 'react'

export default function ContactForm() {
	const [formData, setFormData] = useState({ name: '', email: '', message: '' })
	const [status, setStatus] = useState('neutral') // 'neutral', 'sending', 'success', 'error'

	const handleSubmit = async event => {
		event.preventDefault()

		setStatus('sending')

		try {
			const response = await fetch('/api/contact', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(formData),
			})

			if (response.ok) {
				setFormData({ name: '', email: '', message: '' })
				setStatus('success')
			} else {
				setStatus('error')
			}
		} catch {
			setStatus('error')
		}
	}

	return (
		<form onSubmit={handleSubmit} className="flex w-full flex-col items-center gap-4">
			<div className="w-full text-left">
				<label htmlFor="name" className="mb-1 block text-sm font-bold tracking-wide text-black uppercase">
					Name
				</label>

				<input
					id="name"
					className="w-full border-4 border-black bg-white px-4 py-2 font-semibold text-black transition-colors focus:border-blue-400 focus:outline-none"
					type="text"
					value={formData.name}
					onChange={event => setFormData({ ...formData, name: event.target.value })}
					required
				/>
			</div>

			<div className="w-full text-left">
				<label htmlFor="email" className="mb-1 block text-sm font-bold tracking-wide text-black uppercase">
					Email
				</label>

				<input
					id="email"
					className="w-full border-4 border-black bg-white px-4 py-2 font-semibold text-black transition-colors focus:border-blue-400 focus:outline-none"
					type="email"
					value={formData.email}
					onChange={event => setFormData({ ...formData, email: event.target.value })}
					required
				/>
			</div>

			<div className="w-full text-left">
				<label htmlFor="message" className="mb-1 block text-sm font-bold tracking-wide text-black uppercase">
					Message
				</label>

				<textarea
					id="message"
					className="w-full border-4 border-black bg-white px-4 py-2 font-semibold text-black transition-colors focus:border-blue-400 focus:outline-none"
					rows="4"
					value={formData.message}
					onChange={event => setFormData({ ...formData, message: event.target.value })}
					required
				/>
			</div>

			{status === 'neutral' || status === 'sending' ? (
				<button
					className="w-full cursor-pointer border-4 border-black bg-blue-400 px-4 py-3 font-bold text-black shadow-[4px_4px_0px_0px_#000000] transition-all duration-150 hover:translate-x-[4px] hover:translate-y-[4px] hover:shadow-none disabled:translate-x-0 disabled:translate-y-0 disabled:cursor-not-allowed disabled:opacity-60 disabled:shadow-[4px_4px_0px_0px_#000000]"
					type="submit"
					title="Send Message"
					disabled={status === 'sending' || !formData.name || !formData.email || !formData.message}
				>
					{status === 'sending' ? 'Sending...' : 'Reach Out'}
				</button>
			) : status === 'success' ? (
				<p className="w-full border-4 border-black bg-green-400 px-4 py-3 text-sm font-bold text-black">
					Thank you for your message! I&#39;ll get back to you as soon as possible.
				</p>
			) : (
				status === 'error' && (
					<p className="w-full border-4 border-black bg-red-400 px-4 py-3 text-sm font-bold text-black">
						Oops! Something went wrong while sending your message. Please try again later.
					</p>
				)
			)}
		</form>
	)
}
