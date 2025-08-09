// Custom Cypress commands for Fleet Management testing

/**
 * Creates a fleet configuration with specified equipment counts
 * @param {Object} config - Fleet configuration
 * @param {number} config.excavators - Number of excavators to add (default: current + 0)
 * @param {number} config.trucks - Number of trucks to add (default: current + 0)
 */
Cypress.Commands.add('createFleetConfiguration', (config = {}) => {
  const { excavators = 0, trucks = 0 } = config;
  
  // Add excavators
  for (let i = 0; i < excavators; i++) {
    cy.get('[data-testid="add-excavator-btn"]').click();
    cy.wait(100); // Small delay to prevent race conditions
  }
  
  // Add trucks
  for (let i = 0; i < trucks; i++) {
    cy.get('[data-testid="add-truck-btn"]').click();
    cy.wait(100);
  }
  
  cy.log(`Fleet created: ${excavators + 1} excavators, ${trucks + 1} trucks`);
});

/**
 * Adds maximum allowed fleet (10 excavators, 20 trucks)
 */
Cypress.Commands.add('addMaximumFleet', () => {
  // Add 9 more excavators (1 already exists)
  for (let i = 1; i < 10; i++) {
    cy.get('[data-testid="add-excavator-btn"]').click();
    cy.wait(50);
  }
  
  // Add 19 more trucks (1 already exists) 
  for (let i = 1; i < 20; i++) {
    cy.get('[data-testid="add-truck-btn"]').click();
    cy.wait(30);
  }
  
  // Verify fleet limits reached
  cy.get('[data-testid="excavator-list"]')
    .find('.equipment-item')
    .should('have.length', 10);
    
  cy.get('[data-testid="truck-list"]')
    .find('.equipment-item')
    .should('have.length', 20);
    
  cy.log('Maximum fleet configuration created');
});

/**
 * Configures specific equipment item with values
 * @param {string} equipmentType - 'excavator' or 'truck'
 * @param {number} index - Equipment index (0-based)
 * @param {Object} values - Equipment values to set
 */
Cypress.Commands.add('configureEquipment', (equipmentType, index, values) => {
  const equipmentList = equipmentType === 'excavator' ? 'excavator-list' : 'truck-list';
  
  cy.get(`[data-testid="${equipmentList}"]`)
    .find('.equipment-item')
    .eq(index)
    .within(() => {
      if (equipmentType === 'excavator') {
        if (values.bucketCapacity !== undefined) {
          cy.get('[data-testid*="excavator-capacity"]')
            .clear()
            .type(values.bucketCapacity.toString());
        }
        if (values.cycleTime !== undefined) {
          cy.get('[data-testid*="excavator-cycle"]')
            .clear()
            .type(values.cycleTime.toString());
        }
        if (values.name !== undefined) {
          cy.get('[data-testid*="excavator-name"]')
            .clear()
            .type(values.name);
        }
      } else {
        if (values.capacity !== undefined) {
          cy.get('[data-testid*="truck-capacity"]')
            .clear()
            .type(values.capacity.toString());
        }
        if (values.roundTripTime !== undefined) {
          cy.get('[data-testid*="truck-roundtrip"]')
            .clear()
            .type(values.roundTripTime.toString());
        }
        if (values.name !== undefined) {
          cy.get('[data-testid*="truck-name"]')
            .clear()
            .type(values.name);
        }
      }
    });
    
  cy.log(`Configured ${equipmentType} ${index} with values:`, values);
});

/**
 * Sets up standard pond dimensions for testing
 * @param {Object} dimensions - Pond dimensions
 * @param {number} dimensions.length - Pond length
 * @param {number} dimensions.width - Pond width  
 * @param {number} dimensions.depth - Pond depth
 * @param {number} dimensions.workHours - Work hours per day (optional)
 */
Cypress.Commands.add('setPondDimensions', (dimensions) => {
  const { length, width, depth, workHours = 8 } = dimensions;
  
  cy.get('[data-testid="pond-length-input"]').clear().type(length.toString());
  cy.get('[data-testid="pond-width-input"]').clear().type(width.toString());
  cy.get('[data-testid="pond-depth-input"]').clear().type(depth.toString());
  cy.get('[data-testid="work-hours-input"]').clear().type(workHours.toString());
  
  cy.log(`Pond dimensions set: ${length}x${width}x${depth}, ${workHours}h/day`);
});

/**
 * Waits for calculation to complete and verifies results are displayed
 * @param {number} timeout - Maximum wait time in ms (default: 1000)
 */
Cypress.Commands.add('waitForCalculation', (timeout = 1000) => {
  cy.wait(timeout); // Wait for debounce
  cy.get('[data-testid="timeline-result"]', { timeout: timeout + 1000 })
    .should('be.visible');
  cy.get('[data-testid="timeline-days"]')
    .should('contain.text', 'day')
    .and('not.contain', 'NaN')
    .and('not.contain', 'undefined');
});

/**
 * Measures performance of a callback function
 * @param {Function} callback - Function to measure
 * @param {number} maxTime - Maximum allowed time in ms
 */
Cypress.Commands.add('measurePerformance', (callback, maxTime = 5000) => {
  const startTime = performance.now();
  
  callback();
  
  cy.then(() => {
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    expect(duration).to.be.lessThan(maxTime);
    cy.log(`Operation completed in ${duration.toFixed(2)}ms`);
    
    return duration;
  });
});

/**
 * Verifies fleet limits are properly enforced
 */
Cypress.Commands.add('verifyFleetLimits', () => {
  // Check excavator count and button state
  cy.get('[data-testid="excavator-list"]')
    .find('.equipment-item')
    .its('length')
    .then((excavatorCount) => {
      if (excavatorCount >= 10) {
        cy.get('[data-testid="add-excavator-btn"]').should('be.disabled');
      } else {
        cy.get('[data-testid="add-excavator-btn"]').should('not.be.disabled');
      }
    });
    
  // Check truck count and button state
  cy.get('[data-testid="truck-list"]')
    .find('.equipment-item')
    .its('length')
    .then((truckCount) => {
      if (truckCount >= 20) {
        cy.get('[data-testid="add-truck-btn"]').should('be.disabled');
      } else {
        cy.get('[data-testid="add-truck-btn"]').should('not.be.disabled');
      }
    });
});

/**
 * Verifies equipment numbering is correct
 * @param {string} equipmentType - 'excavator' or 'truck'
 */
Cypress.Commands.add('verifyEquipmentNumbering', (equipmentType) => {
  const equipmentList = equipmentType === 'excavator' ? 'excavator-list' : 'truck-list';
  const equipmentName = equipmentType === 'excavator' ? 'Excavator' : 'Truck';
  
  cy.get(`[data-testid="${equipmentList}"]`)
    .find('.equipment-item')
    .each(($item, index) => {
      cy.wrap($item).should('contain', `${equipmentName} ${index + 1}`);
    });
});

/**
 * Simulates device viewport for testing responsive behavior
 * @param {string} deviceType - 'mobile', 'tablet', or 'desktop'
 */
Cypress.Commands.add('setDevice', (deviceType) => {
  const viewports = {
    mobile: { width: 375, height: 667 },
    tablet: { width: 768, height: 1024 },
    desktop: { width: 1200, height: 800 }
  };
  
  const viewport = viewports[deviceType];
  if (viewport) {
    cy.viewport(viewport.width, viewport.height);
    cy.log(`Device set to ${deviceType} (${viewport.width}x${viewport.height})`);
  }
});

/**
 * Verifies device-specific fleet button visibility
 * @param {string} expectedDevice - Expected device type detection
 */
Cypress.Commands.add('verifyDeviceFleetButtons', (expectedDevice) => {
  cy.get('[data-testid="device-type"]').should('contain', expectedDevice);
  
  if (expectedDevice === 'Mobile') {
    cy.get('[data-testid="add-excavator-btn"]').should('not.exist');
    cy.get('[data-testid="add-truck-btn"]').should('not.exist');
  } else {
    cy.get('[data-testid="add-excavator-btn"]').should('be.visible');
    cy.get('[data-testid="add-truck-btn"]').should('be.visible');
  }
});

/**
 * Creates test scenario with predefined equipment and pond configuration
 * @param {string} scenario - Scenario name ('small', 'medium', 'large', 'maximum')
 */
Cypress.Commands.add('loadTestScenario', (scenario) => {
  const scenarios = {
    small: {
      fleet: { excavators: 1, trucks: 1 },
      pond: { length: 30, width: 20, depth: 4, workHours: 8 },
      equipment: [
        { type: 'excavator', index: 0, values: { bucketCapacity: 2.0, cycleTime: 2.0 } },
        { type: 'truck', index: 0, values: { capacity: 12, roundTripTime: 15 } }
      ]
    },
    medium: {
      fleet: { excavators: 2, trucks: 3 },
      pond: { length: 60, width: 40, depth: 6, workHours: 8 },
      equipment: [
        { type: 'excavator', index: 0, values: { bucketCapacity: 2.5, cycleTime: 1.8 } },
        { type: 'excavator', index: 1, values: { bucketCapacity: 3.0, cycleTime: 2.2 } },
        { type: 'truck', index: 0, values: { capacity: 15, roundTripTime: 18 } }
      ]
    },
    large: {
      fleet: { excavators: 4, trucks: 8 },
      pond: { length: 100, width: 60, depth: 8, workHours: 10 },
      equipment: [
        { type: 'excavator', index: 0, values: { bucketCapacity: 3.5, cycleTime: 1.5 } },
        { type: 'excavator', index: 2, values: { bucketCapacity: 4.0, cycleTime: 1.8 } },
        { type: 'truck', index: 0, values: { capacity: 20, roundTripTime: 25 } }
      ]
    },
    maximum: {
      fleet: { excavators: 9, trucks: 19 }, // Will create 10 and 20 total
      pond: { length: 150, width: 100, depth: 12, workHours: 12 },
      equipment: [
        { type: 'excavator', index: 0, values: { bucketCapacity: 5.0, cycleTime: 1.2 } },
        { type: 'truck', index: 0, values: { capacity: 25, roundTripTime: 30 } }
      ]
    }
  };
  
  const config = scenarios[scenario];
  if (!config) {
    throw new Error(`Unknown scenario: ${scenario}`);
  }
  
  // Create fleet
  cy.createFleetConfiguration(config.fleet);
  
  // Set pond dimensions  
  cy.setPondDimensions(config.pond);
  
  // Configure specific equipment
  config.equipment.forEach(item => {
    cy.configureEquipment(item.type, item.index, item.values);
  });
  
  cy.log(`Test scenario '${scenario}' loaded successfully`);
});

/**
 * Custom keyboard navigation command with tab support
 */
Cypress.Commands.add('tab', { prevSubject: 'element' }, (subject, options = {}) => {
  return cy.wrap(subject, { log: false }).trigger('keydown', {
    keyCode: 9,
    which: 9,
    key: 'Tab',
    shiftKey: options.shift || false
  });
});

/**
 * Custom tap command for mobile testing
 */
Cypress.Commands.add('tap', { prevSubject: 'element' }, (subject, options = {}) => {
  return cy.wrap(subject, { log: false }).trigger('touchstart', options)
    .trigger('touchend', options);
});

/**
 * iPhone viewport shortcuts
 */
Cypress.Commands.add('iPhone8', () => {
  cy.viewport(375, 667);
});

Cypress.Commands.add('iPhoneX', () => {
  cy.viewport(375, 812);
});

Cypress.Commands.add('iPad', () => {
  cy.viewport(768, 1024);
});