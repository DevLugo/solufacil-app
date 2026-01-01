
/** @type {import('tailwindcss').Config} */
export default {
  content: [
  './index.html',
  './src/**/*.{js,ts,jsx,tsx}'
],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#F15A29', // Vibrant orange
          light: '#FF8A5B',
          dark: '#C94820',
        },
        secondary: {
          DEFAULT: '#1B1B3A', // Deep navy
          light: '#2D2D4A',
        },
        success: '#10B981',
        warning: '#F59E0B',
        error: '#EF4444',
        surface: '#F9FAFB',
        border: '#E5E7EB',
        text: {
          primary: '#1B1B3A',
          secondary: '#6B7280',
          disabled: '#D1D5DB',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      boxShadow: {
        'card': '0 2px 8px -2px rgba(27, 27, 58, 0.1)',
        'card-hover': '0 8px 16px -4px rgba(27, 27, 58, 0.1)',
      }
    },
  },
  plugins: [],
}
