// Cypress E2E Support File
// Custom commands and global configurations

// Import new test utilities
import './accessibility-commands.js';
import './memory-testing.js';
import './fleet-commands.js';
import './test-data-factory.js';

// Custom command for tabbing through elements
Cypress.Commands.add('tab', { prevSubject: 'optional' }, (subject, options) => {
  const tabKey = options?.shift ? '{shift}{tab}' : '{tab}';
  
  if (subject) {
    cy.wrap(subject).trigger('keydown', { keyCode: 9, which: 9, shiftKey: options?.shift });
    return cy.focused();
  } else {
    cy.get('body').trigger('keydown', { keyCode: 9, which: 9, shiftKey: options?.shift });
    return cy.focused();
  }
});

// Custom command for accessibility testing
Cypress.Commands.add('checkA11y', (context, options) => {
  // Basic accessibility checks
  if (context) {
    cy.get(context).should('be.visible');
  }
  
  // Check for basic a11y requirements
  cy.get('input').each($input => {
    // Every input should have a label or aria-label
    const hasAriaLabel = $input.attr('aria-label');
    const hasId = $input.attr('id');
    const hasAssociatedLabel = hasId ? Cypress.$(`label[for="${hasId}"]`).length > 0 : false;
    
    if (!hasAriaLabel && !hasAssociatedLabel) {
      throw new Error(`Input element lacks proper labeling: ${$input.attr('data-testid') || 'unknown'}`);
    }
  });
  
  // Check color contrast basics
  cy.get('[data-testid*="error"]').each($error => {
    const styles = window.getComputedStyle($error[0]);
    const color = styles.color;
    
    if (color === 'rgb(0, 0, 0)' || color === 'black') {
      throw new Error('Error text should have distinctive color for visibility');
    }
  });
});

// Custom command for performance measurement
Cypress.Commands.add('measurePerformance', (actionCallback, threshold = 1000) => {
  const startTime = performance.now();
  
  if (actionCallback) {
    actionCallback();
  }
  
  cy.then(() => {
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    cy.task('logPerformance', {
      action: 'measured_action',
      duration: duration,
      threshold: threshold,
      timestamp: new Date().toISOString()
    });
    
    if (duration > threshold) {
      cy.log(`Warning: Action took ${duration}ms (threshold: ${threshold}ms)`);
    }
    
    return cy.wrap(duration);
  });
});

// Custom command for filling form with test data
Cypress.Commands.add('fillFormWithDefaults', (size = 'medium') => {
  const testData = Cypress.env('testData');
  
  let pondData, equipmentData;
  
  switch (size) {
    case 'small':
      pondData = testData.smallPond;
      equipmentData = testData.equipment.smallExcavator;
      break;
    case 'large':
      pondData = testData.largePond;
      equipmentData = testData.equipment.largeExcavator;
      break;
    default:
      pondData = { length: '50', width: '30', depth: '6' };
      equipmentData = { capacity: '3.0', cycle: '2.0' };
  }
  
  cy.get('[data-testid="excavator-capacity-input"]').clear().type(equipmentData.capacity);
  cy.get('[data-testid="excavator-cycle-input"]').clear().type(equipmentData.cycle);
  cy.get('[data-testid="pond-length-input"]').clear().type(pondData.length);
  cy.get('[data-testid="pond-width-input"]').clear().type(pondData.width);
  cy.get('[data-testid="pond-depth-input"]').clear().type(pondData.depth);
});

// Custom command for waiting for calculation
Cypress.Commands.add('waitForCalculation', () => {
  const debounceTime = Cypress.env('performanceThresholds').debounceTime;
  cy.wait(debounceTime);
  cy.get('[data-testid="timeline-result"]', { timeout: 5000 }).should('be.visible');
});

// Custom command for device viewport presets
Cypress.Commands.add('setDevice', (device) => {
  const devices = {
    mobile: { width: 375, height: 667 },
    tablet: { width: 768, height: 1024 },
    desktop: { width: 1200, height: 800 },
    largeDesktop: { width: 1920, height: 1080 }
  };
  
  const viewport = devices[device];
  if (viewport) {
    cy.viewport(viewport.width, viewport.height);
    cy.wait(500); // Allow for responsive transitions
  }
});

// Custom command for testing touch interactions
Cypress.Commands.add('touch', { prevSubject: true }, (subject) => {
  cy.wrap(subject)
    .trigger('touchstart', { touches: [{ clientX: 0, clientY: 0 }] })
    .trigger('touchend');
});

// Custom command for keyboard-only navigation test
Cypress.Commands.add('testKeyboardNavigation', () => {
  let tabCount = 0;
  const maxTabs = 20;
  
  function tabToNext() {
    if (tabCount < maxTabs) {
      cy.tab();
      cy.focused().then($focused => {
        const testId = $focused.attr('data-testid');
        if (testId) {
          cy.log(`Focused on: ${testId}`);
          tabCount++;
          return tabToNext();
        }
      });
    }
  }
  
  cy.get('body').focus();
  return cy.then(() => tabToNext());
});

// Custom command for validation error testing
Cypress.Commands.add('testValidationError', (inputTestId, invalidValue, expectedErrorPattern) => {
  const errorTestId = inputTestId.replace('-input', '-error');
  
  cy.get(`[data-testid="${inputTestId}"]`).clear().type(invalidValue);
  cy.get(`[data-testid="${errorTestId}"]`)
    .should('be.visible')
    .and('match', expectedErrorPattern);
  cy.get('[data-testid="timeline-result"]').should('not.exist');
});

// Custom command for cross-device consistency testing
Cypress.Commands.add('testCrossDeviceConsistency', (formData) => {
  const devices = ['desktop', 'tablet', 'mobile'];
  let previousResult;
  
  devices.forEach((device, index) => {
    cy.setDevice(device);
    
    // Fill form with same data
    Object.entries(formData).forEach(([field, value]) => {
      const fieldName = field.replace(/([A-Z])/g, '-$1').toLowerCase();
      cy.get(`[data-testid="${fieldName}-input"]`).clear().type(value);
    });
    
    cy.waitForCalculation();
    
    cy.get('[data-testid="timeline-days"]').then($days => {
      const currentResult = $days.text();
      
      if (index === 0) {
        previousResult = currentResult;
      } else {
        expect(currentResult).to.equal(previousResult);
      }
    });
  });
});

// Global error handling
Cypress.on('uncaught:exception', (err, runnable) => {
  // Log the error for debugging but don't fail the test for certain errors
  console.log('Uncaught exception:', err.message);
  
  // Don't fail on network errors during config loading (expected in some tests)
  if (err.message.includes('NetworkError') || err.message.includes('Failed to fetch')) {
    return false;
  }
  
  // Allow other errors to fail the test
  return true;
});

// Performance monitoring for all tests
beforeEach(() => {
  // Mark test start time
  cy.window().then(win => {
    win.testStartTime = performance.now();
  });
});

afterEach(() => {
  // Log test performance
  cy.window().then(win => {
    if (win.testStartTime) {
      const testDuration = performance.now() - win.testStartTime;
      cy.task('logPerformance', {
        test: Cypress.currentTest.title,
        duration: testDuration,
        timestamp: new Date().toISOString()
      });
    }
  });
});

// Add support for common device presets
Cypress.Commands.add('iPhone8', () => cy.viewport(375, 667));
Cypress.Commands.add('iPadPro', () => cy.viewport(1024, 1366));
Cypress.Commands.add('desktop1080p', () => cy.viewport(1920, 1080));

// Common test data getters
Cypress.Commands.add('getTestData', (type) => {
  return cy.wrap(Cypress.env('testData')[type]);
});

Cypress.Commands.add('getPerformanceThreshold', (metric) => {
  return cy.wrap(Cypress.env('performanceThresholds')[metric]);
});