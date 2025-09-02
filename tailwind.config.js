/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/assets/javascripts/**/*.js",
    "./app/javascript/**/*.js",
    "./app/assets/stylesheets/**/*.css"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter', 'ui-sans-serif', 'system-ui', 'sans-serif'],
      }
    }
  },
  plugins: [
    require('@tailwindcss/line-clamp')
  ]
}
