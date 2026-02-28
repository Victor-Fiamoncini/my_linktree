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
		<form onSubmit={handleSubmit} className="flex flex-col items-center gap-4 w-full">
			<div className="text-left w-full">
				<label htmlFor="name" className="block text-sm mb-1 text-black font-bold uppercase tracking-wide">
					Name
				</label>

				<input
					id="name"
					className="w-full px-4 py-2 text-black font-semibold border-4 border-black focus:outline-none focus:border-blue-400 transition-colors bg-white"
					type="text"
					value={formData.name}
					onChange={event => setFormData({ ...formData, name: event.target.value })}
					required
				/>
			</div>

			<div className="text-left w-full">
				<label htmlFor="email" className="block text-sm mb-1 text-black font-bold uppercase tracking-wide">
					Email
				</label>

				<input
					id="email"
					className="w-full px-4 py-2 text-black font-semibold border-4 border-black focus:outline-none focus:border-blue-400 transition-colors bg-white"
					type="email"
					value={formData.email}
					onChange={event => setFormData({ ...formData, email: event.target.value })}
					required
				/>
			</div>

			<div className="text-left w-full">
				<label htmlFor="message" className="block text-sm mb-1 text-black font-bold uppercase tracking-wide">
					Message
				</label>

				<textarea
					id="message"
					className="w-full px-4 py-2 text-black font-semibold border-4 border-black focus:outline-none focus:border-blue-400 transition-colors bg-white"
					rows="4"
					value={formData.message}
					onChange={event => setFormData({ ...formData, message: event.target.value })}
					required
				/>
			</div>

			{status === 'neutral' || status === 'sending' ? (
				<button
					className="w-full px-4 py-3 text-black font-bold bg-blue-400 border-4 border-black shadow-[4px_4px_0px_0px_#000000] transition-all duration-150 hover:translate-x-[4px] hover:translate-y-[4px] hover:shadow-none disabled:opacity-60 disabled:translate-x-0 disabled:translate-y-0 disabled:shadow-[4px_4px_0px_0px_#000000] disabled:cursor-not-allowed cursor-pointer"
					type="submit"
					title="Send Message"
					disabled={status === 'sending' || !formData.name || !formData.email || !formData.message}
				>
					{status === 'sending' ? 'Sending...' : 'Reach Out'}
				</button>
			) : status === 'success' ? (
				<p className="w-full text-black text-sm font-bold bg-green-400 border-4 border-black px-4 py-3">
					Thank you for your message! I&#39;ll get back to you as soon as possible.
				</p>
			) : (
				status === 'error' && (
					<p className="w-full text-black text-sm font-bold bg-red-400 border-4 border-black px-4 py-3">
						Oops! Something went wrong while sending your message. Please try again later.
					</p>
				)
			)}
		</form>
	)
}
