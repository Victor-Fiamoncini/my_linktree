'use client'

import { useState } from 'react'

export default function ContactForm() {
	const [formData, setFormData] = useState({ name: '', email: '', message: '' })
	const [status, setStatus] = useState('')

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
		<form onSubmit={handleSubmit} className="space-y-4 w-full sm:w-96">
			<div className="text-left">
				<label htmlFor="name" className="block text-sm mb-1 text-gray-100 font-bold">
					Name
				</label>

				<input
					id="name"
					className="w-full px-4 py-2 text-white font-semibold rounded-lg border-4 border-blue-400 focus:border-white transition-colors"
					type="text"
					value={formData.name}
					onChange={event => setFormData({ ...formData, name: event.target.value })}
					required
				/>
			</div>

			<div className="text-left">
				<label htmlFor="email" className="block text-sm mb-1 text-gray-100 font-bold">
					Email
				</label>

				<input
					id="email"
					className="w-full px-4 py-2 text-white font-semibold rounded-lg border-4 border-blue-400 focus:border-white transition-colors"
					type="email"
					value={formData.email}
					onChange={event => setFormData({ ...formData, email: event.target.value })}
					required
				/>
			</div>

			<div className="text-left">
				<label htmlFor="message" className="block text-sm mb-1 text-gray-100 font-bold">
					Message
				</label>

				<textarea
					id="message"
					className="w-full px-4 py-2 text-white font-semibold rounded-lg border-4 border-blue-400 focus:border-white transition-colors"
					rows="4"
					value={formData.message}
					onChange={event => setFormData({ ...formData, message: event.target.value })}
					required
				/>
			</div>

			<button
				className="w-full px-4 py-2 text-white font-semibold rounded-lg bg-blue-400 cursor-pointer disabled:opacity-80 transition-colors"
				type="submit"
				disabled={status === 'sending' || !formData.name || !formData.email || !formData.message}
			>
				{status === 'sending' ? 'Sending...' : 'Send Message'}
			</button>

			{status === 'success' && (
				<p className="text-green-500 text-sm font-semibold">
					Thank you for your message! I’ll get back to you as soon as possible.
				</p>
			)}

			{status === 'error' && (
				<p className="text-red-600 text-sm font-semibold">
					Oops! Something went wrong while sending your message. Please try again later.
				</p>
			)}
		</form>
	)
}
