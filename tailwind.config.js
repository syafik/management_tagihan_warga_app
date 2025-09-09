/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/views/**/**/*.html.erb", 
    "./app/helpers/**/*.rb",
    "./app/assets/stylesheets/**/*.css",
    "./app/frontend/**/*.js",
    "./app/**/*.rb"
  ],
  theme: {
    extend: {},
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
}