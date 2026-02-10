/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      // Admin panel color system (SOURCE: Android public app AppTheme)
      // Rule: Only Blue (#2874F0), Orange (#FF9F00), and Greys/White.
      colors: {
        // Primary action blue
        blue: {
          600: '#2874F0',
          700: '#2874F0',
        },

        // Secondary/CTA orange (+ light background tint)
        orange: {
          50: '#FFF1E6',
          600: '#FF9F00',
          700: '#FF9F00',
        },

        // Legacy usages mapped into palette
        amber: {
          50: '#FFF1E6',
          700: '#FF9F00',
        },
        emerald: {
          50: '#F5F7FA',
          100: '#FFFFFF',
          200: '#2874F0',
          700: '#2874F0',
          900: '#2874F0',
        },
        rose: {
          50: '#FFF1E6',
          100: '#FFF1E6',
          200: '#FF9F00',
          700: '#FF9F00',
          800: '#FF9F00',
          900: '#FF9F00',
        },

        // Neutral greys (backgrounds, borders, text)
        slate: {
          50: '#F5F7FA',
          100: '#E5E7EB',
          200: '#E5E7EB',
          300: '#E5E7EB',
          400: '#9E9E9E',
          500: '#757575',
          600: '#757575',
          700: '#212121',
          800: '#212121',
          900: '#212121',
        },
      },
    },
  },
  plugins: [],
}

