const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:1234',
    specPattern: 'tests/E2E/cypress/integration/**/*.spec.js',
    supportFile: false,
    setupNodeEvents(on, config) {
      // implement node event listeners here
    },
  },
  viewport: {
    width: 1200,
    height: 800
  },
  video: false,
  screenshots: {
    enabled: false
  },
  defaultCommandTimeout: 10000,
  pageLoadTimeout: 30000,
  viewportWidth: 1200,
  viewportHeight: 800
})