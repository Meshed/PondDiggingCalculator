const { defineConfig } = require('cypress')

module.exports = defineConfig({
  e2e: {
    baseUrl: 'http://localhost:1234',
    specPattern: 'tests/E2E/cypress/integration/**/*.spec.js',
    supportFile: 'tests/E2E/cypress/support/e2e.js',
    setupNodeEvents(on, config) {
      // Performance monitoring
      on('task', {
        logPerformance(data) {
          console.log('Performance Metrics:', data);
          return null;
        }
      });

      // Browser launch options for accessibility testing
      on('before:browser:launch', (browser, launchOptions) => {
        if (browser.name === 'chrome') {
          // Enable accessibility features
          launchOptions.args.push('--force-prefers-reduced-motion');
          launchOptions.args.push('--enable-experimental-accessibility-features');
        }
        return launchOptions;
      });

      return config;
    },
    // Test filtering and organization
    excludeSpecPattern: [
      '**/node_modules/**',
      '**/examples/**'
    ],
    env: {
      // Performance thresholds
      performanceThresholds: {
        calculationTime: 100,
        pageLoadTime: 2000,
        debounceTime: 400
      },
      // Test data
      testData: {
        smallPond: {
          length: '30',
          width: '20', 
          depth: '4'
        },
        largePond: {
          length: '100',
          width: '80',
          depth: '12'
        },
        equipment: {
          smallExcavator: { capacity: '2.0', cycle: '2.5' },
          largeExcavator: { capacity: '4.5', cycle: '1.8' },
          smallTruck: { capacity: '10', roundTrip: '12' },
          largeTruck: { capacity: '20', roundTrip: '25' }
        }
      },
      // Browser matrix for cross-browser testing
      browsers: ['chrome', 'firefox', 'edge']
    }
  },
  // Device configurations for responsive testing
  viewport: {
    width: 1200,
    height: 800
  },
  viewportWidth: 1200,
  viewportHeight: 800,
  
  // Enhanced timeout settings for comprehensive tests
  defaultCommandTimeout: 10000,
  pageLoadTimeout: 30000,
  responseTimeout: 15000,
  requestTimeout: 10000,
  
  // Test execution settings
  video: true,
  videoCompression: 32,
  screenshotOnRunFailure: true,
  screenshots: {
    enabled: true
  },
  
  // Retry settings for flaky test handling
  retries: {
    runMode: 2,
    openMode: 0
  },
  
  // Performance and stability settings
  watchForFileChanges: false,
  chromeWebSecurity: false,
  
  
  // Accessibility and usability settings
  scrollBehavior: 'center',
  animationDistanceThreshold: 5,
  waitForAnimations: true,
  
  // Reporter configuration for CI/CD
  reporter: 'spec',
  reporterOptions: {
    verbose: true
  }
})