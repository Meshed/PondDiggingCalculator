/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{elm,html,js}", "./public/*.html"],
  theme: {
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