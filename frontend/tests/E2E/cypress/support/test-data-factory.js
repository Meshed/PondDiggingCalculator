// Enhanced Test Data Factory for Comprehensive Testing

/**
 * Test Data Factory for Pond Digging Calculator
 * Provides consistent, realistic test data for various scenarios
 */

// Equipment configurations for different project sizes
const EQUIPMENT_PROFILES = {
  // Small residential projects
  residential: {
    excavators: [
      { bucketCapacity: 1.5, cycleTime: 2.5, name: 'Mini Excavator', isActive: true },
      { bucketCapacity: 2.0, cycleTime: 2.2, name: 'Compact Excavator', isActive: true }
    ],
    trucks: [
      { capacity: 8, roundTripTime: 12, name: 'Small Dump Truck', isActive: true },
      { capacity: 10, roundTripTime: 15, name: 'Medium Dump Truck', isActive: true }
    ]
  },
  
  // Medium commercial projects
  commercial: {
    excavators: [
      { bucketCapacity: 2.5, cycleTime: 2.0, name: 'Standard Excavator', isActive: true },
      { bucketCapacity: 3.0, cycleTime: 1.8, name: 'Large Excavator', isActive: true },
      { bucketCapacity: 3.5, cycleTime: 1.6, name: 'Heavy Excavator', isActive: true }
    ],
    trucks: [
      { capacity: 15, roundTripTime: 18, name: 'Commercial Truck 1', isActive: true },
      { capacity: 18, roundTripTime: 22, name: 'Commercial Truck 2', isActive: true },
      { capacity: 20, roundTripTime: 25, name: 'Heavy Dump Truck', isActive: true }
    ]
  },
  
  // Large industrial projects
  industrial: {
    excavators: [
      { bucketCapacity: 4.0, cycleTime: 1.4, name: 'Industrial Excavator 1', isActive: true },
      { bucketCapacity: 4.5, cycleTime: 1.2, name: 'Industrial Excavator 2', isActive: true },
      { bucketCapacity: 5.0, cycleTime: 1.0, name: 'Heavy Industrial', isActive: true },
      { bucketCapacity: 3.8, cycleTime: 1.5, name: 'Support Excavator', isActive: true }
    ],
    trucks: [
      { capacity: 22, roundTripTime: 28, name: 'Industrial Truck 1', isActive: true },
      { capacity: 25, roundTripTime: 30, name: 'Industrial Truck 2', isActive: true },
      { capacity: 20, roundTripTime: 26, name: 'Industrial Truck 3', isActive: true },
      { capacity: 28, roundTripTime: 35, name: 'Heavy Industrial Truck', isActive: true },
      { capacity: 24, roundTripTime: 32, name: 'Support Truck', isActive: true }
    ]
  },
  
  // Maximum performance fleet
  maximum: {
    excavators: [
      { bucketCapacity: 5.5, cycleTime: 0.8, name: 'Max Performance 1', isActive: true },
      { bucketCapacity: 5.2, cycleTime: 0.9, name: 'Max Performance 2', isActive: true },
      { bucketCapacity: 4.8, cycleTime: 1.0, name: 'Max Performance 3', isActive: true },
      { bucketCapacity: 5.0, cycleTime: 0.85, name: 'Max Performance 4', isActive: true },
      { bucketCapacity: 4.5, cycleTime: 1.1, name: 'Support Max 1', isActive: true },
      { bucketCapacity: 4.7, cycleTime: 1.05, name: 'Support Max 2', isActive: true }
    ],
    trucks: [
      { capacity: 30, roundTripTime: 20, name: 'Ultra Truck 1', isActive: true },
      { capacity: 28, roundTripTime: 22, name: 'Ultra Truck 2', isActive: true },
      { capacity: 32, roundTripTime: 24, name: 'Ultra Truck 3', isActive: true },
      { capacity: 29, roundTripTime: 21, name: 'Ultra Truck 4', isActive: true },
      { capacity: 31, roundTripTime: 23, name: 'Ultra Truck 5', isActive: true },
      { capacity: 27, roundTripTime: 19, name: 'Ultra Truck 6', isActive: true },
      { capacity: 26, roundTripTime: 25, name: 'Support Ultra 1', isActive: true },
      { capacity: 33, roundTripTime: 26, name: 'Support Ultra 2', isActive: true }
    ]
  }
};

// Pond configurations for different project types
const POND_PROFILES = {
  // Small backyard ponds
  backyard: {
    small: { length: 12, width: 8, depth: 3, workHours: 6, description: 'Small backyard pond' },
    medium: { length: 18, width: 12, depth: 4, workHours: 7, description: 'Medium backyard pond' },
    large: { length: 25, width: 15, depth: 5, workHours: 8, description: 'Large backyard pond' }
  },
  
  // Commercial water features
  commercial: {
    small: { length: 35, width: 25, depth: 6, workHours: 8, description: 'Small commercial pond' },
    medium: { length: 50, width: 35, depth: 7, workHours: 9, description: 'Medium commercial pond' },
    large: { length: 75, width: 50, depth: 8, workHours: 10, description: 'Large commercial pond' }
  },
  
  // Industrial retention ponds
  industrial: {
    small: { length: 80, width: 60, depth: 10, workHours: 10, description: 'Small retention pond' },
    medium: { length: 120, width: 80, depth: 12, workHours: 11, description: 'Medium retention pond' },
    large: { length: 180, width: 120, depth: 15, workHours: 12, description: 'Large retention pond' }
  },
  
  // Agricultural irrigation ponds
  agricultural: {
    small: { length: 60, width: 40, depth: 8, workHours: 9, description: 'Small irrigation pond' },
    medium: { length: 100, width: 70, depth: 10, workHours: 10, description: 'Medium irrigation pond' },
    large: { length: 150, width: 100, depth: 12, workHours: 11, description: 'Large irrigation pond' }
  },
  
  // Extreme test cases
  extreme: {
    tiny: { length: 5, width: 3, depth: 1, workHours: 4, description: 'Extremely small pond' },
    narrow: { length: 100, width: 5, depth: 6, workHours: 8, description: 'Long narrow pond' },
    deep: { length: 30, width: 20, depth: 20, workHours: 10, description: 'Very deep pond' },
    massive: { length: 250, width: 200, depth: 18, workHours: 14, description: 'Massive industrial pond' }
  }
};

// Performance test scenarios
const PERFORMANCE_SCENARIOS = {
  baseline: {
    equipment: 'residential',
    pond: 'backyard.medium',
    expectedRange: { min: 1, max: 10 },
    description: 'Baseline performance test'
  },
  
  moderate: {
    equipment: 'commercial',
    pond: 'commercial.medium',
    expectedRange: { min: 5, max: 25 },
    description: 'Moderate complexity test'
  },
  
  complex: {
    equipment: 'industrial',
    pond: 'industrial.large',
    expectedRange: { min: 10, max: 50 },
    description: 'Complex fleet calculation test'
  },
  
  maximum: {
    equipment: 'maximum',
    pond: 'extreme.massive',
    expectedRange: { min: 1, max: 30 },
    description: 'Maximum performance test'
  }
};

// Error test cases
const ERROR_TEST_CASES = {
  validation: {
    negativeValues: [
      { field: 'excavator-capacity-input', value: '-2.5', expectedError: 'positive number' },
      { field: 'pond-depth-input', value: '-5', expectedError: 'positive number' },
      { field: 'work-hours-input', value: '-8', expectedError: 'positive number' }
    ],
    
    zeroValues: [
      { field: 'excavator-capacity-input', value: '0', expectedError: 'greater than zero' },
      { field: 'truck-capacity-input', value: '0', expectedError: 'greater than zero' },
      { field: 'pond-length-input', value: '0', expectedError: 'greater than zero' }
    ],
    
    extremeValues: [
      { field: 'excavator-capacity-input', value: '1000', expectedError: 'reasonable range' },
      { field: 'pond-depth-input', value: '100', expectedError: 'reasonable range' },
      { field: 'work-hours-input', value: '30', expectedError: 'valid work hours' }
    ],
    
    invalidFormats: [
      { field: 'excavator-capacity-input', value: 'abc', expectedError: 'number' },
      { field: 'pond-length-input', value: '12.34.56', expectedError: 'valid number' },
      { field: 'work-hours-input', value: '8.', expectedError: 'valid number' }
    ]
  }
};

// Device-specific test configurations
const DEVICE_SCENARIOS = {
  mobile: {
    viewport: { width: 375, height: 667 },
    equipment: 'residential', // Simple fleet for mobile
    pond: 'backyard.small',
    features: ['simplified-interface', 'touch-optimized'],
    restrictions: ['no-fleet-management', 'single-equipment-only'],
    description: 'Mobile device scenario'
  },
  
  tablet: {
    viewport: { width: 768, height: 1024 },
    equipment: 'commercial',
    pond: 'commercial.medium', 
    features: ['fleet-management', 'responsive-layout'],
    restrictions: [],
    description: 'Tablet device scenario'
  },
  
  desktop: {
    viewport: { width: 1200, height: 800 },
    equipment: 'industrial',
    pond: 'industrial.large',
    features: ['full-fleet-management', 'advanced-features'],
    restrictions: [],
    description: 'Desktop device scenario'
  },
  
  largeScreen: {
    viewport: { width: 1920, height: 1080 },
    equipment: 'maximum',
    pond: 'extreme.massive',
    features: ['full-features', 'large-display-optimized'],
    restrictions: [],
    description: 'Large screen scenario'
  }
};

/**
 * Test Data Factory Class
 */
class TestDataFactory {
  /**
   * Get equipment configuration for a profile
   */
  static getEquipmentProfile(profileName) {
    const profile = EQUIPMENT_PROFILES[profileName];
    if (!profile) {
      throw new Error(`Unknown equipment profile: ${profileName}`);
    }
    return JSON.parse(JSON.stringify(profile)); // Deep clone
  }
  
  /**
   * Get pond configuration for a profile
   */
  static getPondProfile(profilePath) {
    const [category, size] = profilePath.split('.');
    const profile = POND_PROFILES[category]?.[size];
    if (!profile) {
      throw new Error(`Unknown pond profile: ${profilePath}`);
    }
    return { ...profile }; // Shallow clone
  }
  
  /**
   * Get performance scenario
   */
  static getPerformanceScenario(scenarioName) {
    const scenario = PERFORMANCE_SCENARIOS[scenarioName];
    if (!scenario) {
      throw new Error(`Unknown performance scenario: ${scenarioName}`);
    }
    return { ...scenario };
  }
  
  /**
   * Get error test case
   */
  static getErrorTestCase(category) {
    const cases = ERROR_TEST_CASES.validation[category];
    if (!cases) {
      throw new Error(`Unknown error test category: ${category}`);
    }
    return cases.map(c => ({ ...c })); // Clone array of objects
  }
  
  /**
   * Get device scenario
   */
  static getDeviceScenario(deviceType) {
    const scenario = DEVICE_SCENARIOS[deviceType];
    if (!scenario) {
      throw new Error(`Unknown device scenario: ${deviceType}`);
    }
    return { ...scenario };
  }
  
  /**
   * Generate complete test scenario
   */
  static generateScenario(options = {}) {
    const {
      equipment = 'commercial',
      pond = 'commercial.medium',
      device = 'desktop',
      includeVariations = false
    } = options;
    
    const scenario = {
      equipment: this.getEquipmentProfile(equipment),
      pond: this.getPondProfile(pond),
      device: this.getDeviceScenario(device),
      timestamp: new Date().toISOString(),
      id: `scenario_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`
    };
    
    if (includeVariations) {
      scenario.variations = this.generateVariations(scenario);
    }
    
    return scenario;
  }
  
  /**
   * Generate test variations for a scenario
   */
  static generateVariations(baseScenario) {
    const variations = [];
    
    // Equipment variations
    const equipment = baseScenario.equipment;
    if (equipment.excavators.length > 0) {
      variations.push({
        type: 'equipment_efficiency',
        description: 'Improved excavator efficiency',
        changes: {
          'excavators.0.cycleTime': equipment.excavators[0].cycleTime * 0.8
        }
      });
    }
    
    // Pond size variations
    const pond = baseScenario.pond;
    variations.push({
      type: 'pond_size',
      description: '25% larger pond',
      changes: {
        'pond.length': Math.round(pond.length * 1.25),
        'pond.width': Math.round(pond.width * 1.25)
      }
    });
    
    // Work schedule variations
    variations.push({
      type: 'work_schedule',
      description: 'Extended work hours',
      changes: {
        'pond.workHours': Math.min(pond.workHours + 2, 14)
      }
    });
    
    return variations;
  }
  
  /**
   * Generate realistic random values within constraints
   */
  static generateRandomValues(constraints = {}) {
    const {
      excavatorCapacityRange = [1.5, 5.0],
      excavatorCycleTimeRange = [1.0, 3.0],
      truckCapacityRange = [8, 30],
      truckRoundTripRange = [10, 40],
      pondLengthRange = [10, 200],
      pondWidthRange = [8, 150],
      pondDepthRange = [2, 20],
      workHoursRange = [4, 12]
    } = constraints;
    
    const random = (min, max, decimals = 1) => {
      const value = Math.random() * (max - min) + min;
      return parseFloat(value.toFixed(decimals));
    };
    
    return {
      excavator: {
        bucketCapacity: random(...excavatorCapacityRange),
        cycleTime: random(...excavatorCycleTimeRange)
      },
      truck: {
        capacity: random(...truckCapacityRange, 0),
        roundTripTime: random(...truckRoundTripRange, 0)
      },
      pond: {
        length: random(...pondLengthRange, 0),
        width: random(...pondWidthRange, 0),
        depth: random(...pondDepthRange),
        workHours: random(...workHoursRange)
      }
    };
  }
  
  /**
   * Get test matrix for comprehensive testing
   */
  static getTestMatrix() {
    const matrix = [];
    
    const equipmentProfiles = Object.keys(EQUIPMENT_PROFILES);
    const pondCategories = Object.keys(POND_PROFILES);
    const deviceTypes = Object.keys(DEVICE_SCENARIOS);
    
    // Generate combinations for comprehensive testing
    equipmentProfiles.forEach(equipment => {
      pondCategories.forEach(pondCategory => {
        const sizes = Object.keys(POND_PROFILES[pondCategory]);
        sizes.forEach(size => {
          deviceTypes.forEach(device => {
            matrix.push({
              equipment,
              pond: `${pondCategory}.${size}`,
              device,
              id: `${equipment}_${pondCategory}_${size}_${device}`,
              priority: this.calculateTestPriority(equipment, pondCategory, device)
            });
          });
        });
      });
    });
    
    // Sort by priority (high priority first)
    return matrix.sort((a, b) => b.priority - a.priority);
  }
  
  /**
   * Calculate test priority for scenario combinations
   */
  static calculateTestPriority(equipment, pondCategory, device) {
    let priority = 1;
    
    // Common scenarios get higher priority
    if (equipment === 'commercial' && pondCategory === 'commercial') priority += 3;
    if (equipment === 'residential' && pondCategory === 'backyard') priority += 2;
    if (device === 'desktop') priority += 2;
    if (device === 'mobile') priority += 1;
    
    // Edge cases get moderate priority
    if (equipment === 'maximum' || pondCategory === 'extreme') priority += 1;
    
    return priority;
  }
  
  /**
   * Validate scenario configuration
   */
  static validateScenario(scenario) {
    const errors = [];
    
    if (!scenario.equipment) {
      errors.push('Missing equipment configuration');
    } else {
      if (!scenario.equipment.excavators || scenario.equipment.excavators.length === 0) {
        errors.push('At least one excavator required');
      }
      if (!scenario.equipment.trucks || scenario.equipment.trucks.length === 0) {
        errors.push('At least one truck required');
      }
    }
    
    if (!scenario.pond) {
      errors.push('Missing pond configuration');
    } else {
      if (scenario.pond.length <= 0 || scenario.pond.width <= 0 || scenario.pond.depth <= 0) {
        errors.push('Pond dimensions must be positive');
      }
      if (scenario.pond.workHours <= 0 || scenario.pond.workHours > 24) {
        errors.push('Work hours must be between 1 and 24');
      }
    }
    
    return {
      isValid: errors.length === 0,
      errors
    };
  }
}

// Export factory and data for use in tests
if (typeof module !== 'undefined' && module.exports) {
  // Node.js environment
  module.exports = {
    TestDataFactory,
    EQUIPMENT_PROFILES,
    POND_PROFILES,
    PERFORMANCE_SCENARIOS,
    ERROR_TEST_CASES,
    DEVICE_SCENARIOS
  };
} else {
  // Browser environment
  window.TestDataFactory = TestDataFactory;
  window.EQUIPMENT_PROFILES = EQUIPMENT_PROFILES;
  window.POND_PROFILES = POND_PROFILES;
  window.PERFORMANCE_SCENARIOS = PERFORMANCE_SCENARIOS;
  window.ERROR_TEST_CASES = ERROR_TEST_CASES;
  window.DEVICE_SCENARIOS = DEVICE_SCENARIOS;
}

// Cypress-specific extensions
if (typeof Cypress !== 'undefined') {
  /**
   * Cypress command to load a test scenario
   */
  Cypress.Commands.add('loadTestDataScenario', (scenarioOptions) => {
    const scenario = TestDataFactory.generateScenario(scenarioOptions);
    const validation = TestDataFactory.validateScenario(scenario);
    
    if (!validation.isValid) {
      throw new Error(`Invalid scenario: ${validation.errors.join(', ')}`);
    }
    
    // Set device viewport
    if (scenario.device.viewport) {
      cy.viewport(scenario.device.viewport.width, scenario.device.viewport.height);
    }
    
    // Load equipment configuration
    const equipment = scenario.equipment;
    for (let i = 1; i < equipment.excavators.length; i++) {
      cy.get('[data-testid="add-excavator-btn"]').click();
      cy.wait(100);
    }
    
    for (let i = 1; i < equipment.trucks.length; i++) {
      cy.get('[data-testid="add-truck-btn"]').click();
      cy.wait(100);
    }
    
    // Configure equipment
    equipment.excavators.forEach((excavator, index) => {
      cy.configureEquipment('excavator', index, excavator);
    });
    
    equipment.trucks.forEach((truck, index) => {
      cy.configureEquipment('truck', index, truck);
    });
    
    // Set pond configuration
    cy.setPondDimensions(scenario.pond);
    
    // Return scenario for reference
    return cy.wrap(scenario);
  });
  
  /**
   * Cypress command to run test matrix
   */
  Cypress.Commands.add('runTestMatrix', (options = {}) => {
    const { maxTests = 10, priority = 3 } = options;
    const matrix = TestDataFactory.getTestMatrix()
      .filter(test => test.priority >= priority)
      .slice(0, maxTests);
    
    const results = [];
    
    matrix.forEach((testCase, index) => {
      cy.log(`Running test matrix case ${index + 1}/${matrix.length}: ${testCase.id}`);
      
      cy.loadTestDataScenario({
        equipment: testCase.equipment,
        pond: testCase.pond,
        device: testCase.device
      }).then(scenario => {
        cy.waitForCalculation();
        
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        cy.get('[data-testid="timeline-days"]')
          .invoke('text')
          .then(result => {
            results.push({
              testCase: testCase.id,
              result: result,
              scenario: scenario
            });
          });
      });
      
      if (index < matrix.length - 1) {
        cy.reload(); // Reset between tests
      }
    });
    
    return cy.wrap(results);
  });
}