'use client'

import { useState } from 'react'

const INPUT_CLASS_NAME =
	'bg-ctp-mantle border-ctp-surface1 text-ctp-text rounded-btn focus:border-ctp-blue w-full border px-[14px] py-3 text-[15px] transition-colors outline-none'

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
		<form onSubmit={handleSubmit} className="grid w-full gap-4">
			<div className="grid grid-cols-1 gap-4 min-[500px]:grid-cols-2">
				<label className="grid gap-2">
					<span className="text-ctp-subtext0 font-mono text-xs">name</span>

					<input
						id="name"
						className={INPUT_CLASS_NAME}
						type="text"
						value={formData.name}
						onChange={event => setFormData({ ...formData, name: event.target.value })}
						required
					/>
				</label>

				<label className="grid gap-2">
					<span className="text-ctp-subtext0 font-mono text-xs">email</span>

					<input
						id="email"
						className={INPUT_CLASS_NAME}
						type="email"
						value={formData.email}
						onChange={event => setFormData({ ...formData, email: event.target.value })}
						required
					/>
				</label>
			</div>

			<label className="grid gap-2">
				<span className="text-ctp-subtext0 font-mono text-xs">message</span>

				<textarea
					id="message"
					className={`${INPUT_CLASS_NAME} resize-y`}
					rows="5"
					value={formData.message}
					onChange={event => setFormData({ ...formData, message: event.target.value })}
					required
				/>
			</label>

			{status === 'neutral' || status === 'sending' ? (
				<button
					className="bg-ctp-green text-ctp-crust rounded-btn hover:bg-ctp-teal cursor-pointer justify-self-center px-[26px] py-[13px] font-semibold transition-all duration-200 hover:-translate-y-0.5 hover:shadow-[0_0_20px_-4px_var(--color-ctp-teal)] disabled:cursor-not-allowed disabled:opacity-60 disabled:hover:translate-y-0 disabled:hover:shadow-none max-[531px]:w-full min-[500px]:justify-self-start"
					type="submit"
					title="Send Message"
					disabled={status === 'sending' || !formData.name || !formData.email || !formData.message}
				>
					{status === 'sending' ? 'Sending...' : 'Reach Out'}
				</button>
			) : status === 'success' ? (
				<p className="bg-ctp-surface0 text-ctp-green rounded-btn w-full px-4 py-3 text-sm">
					Thank you for your message! I&#39;ll get back to you as soon as possible.
				</p>
			) : (
				status === 'error' && (
					<p className="bg-ctp-surface0 text-ctp-red rounded-btn w-full px-4 py-3 text-sm">
						Oops! Something went wrong while sending your message. Please try again later.
					</p>
				)
			)}
		</form>
	)
}
