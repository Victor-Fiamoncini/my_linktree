import { transform as esbuildTransform } from 'esbuild'
import path from 'path'
import { fileURLToPath } from 'url'
import { defineConfig } from 'vitest/config'

const __dirname = fileURLToPath(new URL('.', import.meta.url))

// @vitejs/plugin-react skips SSR mode transforms (which Vitest uses).
// This plugin explicitly transforms JSX in all .js/.jsx source files using
// esbuild's automatic React runtime, so Vitest can load Next.js components
// that use the .js extension with JSX content.
const jsxPlugin = () => ({
	name: 'jsx-in-js',
	enforce: 'pre',
	async transform(code, id) {
		if (!/\.(js|jsx)$/.test(id) || id.includes('node_modules')) return null

		const result = await esbuildTransform(code, {
			loader: 'jsx',
			jsx: 'automatic',
			sourcemap: 'inline',
			sourcefile: id,
		})

		return { code: result.code, map: null }
	},
})

export default defineConfig({
	plugins: [jsxPlugin()],
	test: {
		setupFiles: ['./src/e2e-setup.js'],
	},
	resolve: {
		alias: {
			'@': path.resolve(__dirname, './src'),
		},
	},
})
