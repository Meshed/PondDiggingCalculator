/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{elm,html,js}", "./public/*.html"],
  safelist: [
    'bg-orange-600',
    'hover:bg-orange-700', 
    'text-orange-600',
    'focus:ring-orange-500'
  ],
  theme: {
    screens: {
      'mobile': '320px',
      'tablet': '768px', 
      'desktop': '1024px',
      'wide': '1920px'
    },
    extend: {
      colors: {
        'pond-blue': '#3b82f6',
        'earth-brown': '#92400e',
        'equipment-yellow': '#fbbf24'
      }
    },
  },
  plugins: [],
}