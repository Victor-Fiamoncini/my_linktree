import { ImageResponse } from 'next/og'

import { GetXpYearsUseCase } from '@/core/application/use-cases/get-xp-years-use-case'

export const alt = 'Victor Fiamoncini — Software Engineer'
export const size = { width: 1200, height: 630 }
export const d = 'image/png'

export default async function OpengraphImage() {
	const getXpYearsUseCase = new GetXpYearsUseCase()

	return new ImageResponse(
		<div
			style={{
				width: '100%',
				height: '100%',
				display: 'flex',
				flexDirection: 'column',
				justifyContent: 'center',
				alignItems: 'center',
				backgroundColor: '#60a5fa',
				fontFamily: 'sans-serif',
			}}
		>
			<div style={{ fontSize: 72, fontWeight: 700, color: '#000' }}>Victor Fiamoncini</div>
			<div style={{ fontSize: 36, color: '#111', marginTop: 16 }}>
				{`Software Engineer · ${getXpYearsUseCase.execute()}+ years experience`}
			</div>
		</div>,
		{ ...size }
	)
}
