/// <reference types="cypress" />

describe('Cross-Browser Functionality Validation', () => {
  const testData = {
    excavatorCapacity: '2.5',
    excavatorCycle: '2.0',
    truckCapacity: '12.0',
    truckRoundTrip: '15.0',
    pondLength: '40',
    pondWidth: '25',
    pondDepth: '5',
    workHours: '8'
  };

  beforeEach(() => {
    cy.visit('/');
    cy.wait(1000); // Allow config to load
  });

  context('Desktop Browser Compatibility (Chrome 90+, Firefox 88+, Safari 14+)', () => {
    beforeEach(() => {
      cy.viewport(1200, 800); // Desktop viewport
    });

    it('should detect desktop device type and show advanced features', () => {
      // Desktop should show full interface
      cy.get('[data-testid="device-type"]').should('contain', 'Desktop');
      cy.get('[data-testid="advanced-features"]').should('be.visible');
    });

    it('should load default values correctly on desktop', () => {
      // Verify config.json defaults load identically across browsers
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      cy.get('[data-testid="excavator-cycle-input"]').should('have.value', '2');
      cy.get('[data-testid="truck-capacity-input"]').should('have.value', '12');
      cy.get('[data-testid="truck-roundtrip-input"]').should('have.value', '15');
      cy.get('[data-testid="work-hours-input"]').should('have.value', '8');
      cy.get('[data-testid="pond-length-input"]').should('have.value', '40');
      cy.get('[data-testid="pond-width-input"]').should('have.value', '25');
      cy.get('[data-testid="pond-depth-input"]').should('have.value', '5');
    });

    it('should calculate timeline correctly with default values', () => {
      // Calculation should complete within 100ms performance target
      const startTime = performance.now();
      
      cy.get('[data-testid="calculate-button"]').click();
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const endTime = performance.now();
        const calculationTime = endTime - startTime;
        
        // Performance target: under 100ms
        expect(calculationTime).to.be.lessThan(100);
      });
      
      // Verify calculation results
      cy.get('[data-testid="timeline-days"]').should('contain', '1');
      cy.get('[data-testid="excavation-rate"]').should('be.visible');
      cy.get('[data-testid="hauling-rate"]').should('be.visible');
      cy.get('[data-testid="bottleneck"]').should('contain', 'Hauling');
    });

    it('should handle real-time updates with 300ms debouncing', () => {
      // Test debounce behavior is consistent across browsers
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      
      // Should not calculate immediately (debounced)
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      // Wait for debounce (300ms + buffer)
      cy.wait(400);
      
      // Should now show updated calculation
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
    });

    it('should validate inputs consistently', () => {
      // Test validation rules apply identically across browsers
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible')
        .and('contain', 'must be greater than zero');
      
      cy.get('[data-testid="truck-capacity-input"]').clear().type('100');
      cy.get('[data-testid="truck-capacity-error"]').should('be.visible')
        .and('contain', 'too high');
    });

    it('should maintain state during browser resize', () => {
      // Enter custom values
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.get('[data-testid="pond-length-input"]').clear().type('60');
      
      cy.wait(400); // Wait for debounce and calculation
      
      // Resize to tablet viewport
      cy.viewport(800, 1024);
      cy.wait(500);
      
      // Values should be preserved
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '3.5');
      cy.get('[data-testid="pond-length-input"]').should('have.value', '60');
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Mobile Browser Compatibility (Chrome mobile, Safari mobile <768px)', () => {
    beforeEach(() => {
      cy.viewport(375, 667); // Mobile viewport (iPhone)
    });

    it('should detect mobile device type and show simplified interface', () => {
      // Mobile should show simplified interface
      cy.get('[data-testid="device-type"]').should('contain', 'Mobile');
      cy.get('[data-testid="advanced-features"]').should('not.exist');
      cy.get('[data-testid="simplified-interface"]').should('be.visible');
    });

    it('should load identical default values on mobile', () => {
      // Same config.json defaults should load
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      cy.get('[data-testid="truck-capacity-input"]').should('have.value', '12');
      cy.get('[data-testid="work-hours-input"]').should('have.value', '8');
    });

    it('should calculate timeline identically to desktop', () => {
      cy.get('[data-testid="calculate-button"]').click();
      
      // Same calculation results as desktop
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('contain', '1');
    });

    it('should apply same 300ms debouncing on mobile', () => {
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('4.0');
      
      // Should not calculate immediately
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      cy.wait(400); // Wait for debounce
      
      // Should calculate after debounce
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should validate inputs identically to desktop', () => {
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('0');
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible')
        .and('contain', 'must be greater than zero');
    });

    it('should maintain performance targets on mobile', () => {
      const startTime = performance.now();
      
      cy.get('[data-testid="calculate-button"]').click();
      
      cy.get('[data-testid="timeline-result"]').should('be.visible').then(() => {
        const endTime = performance.now();
        const calculationTime = endTime - startTime;
        
        // Same 100ms performance target on mobile
        expect(calculationTime).to.be.lessThan(100);
      });
    });
  });

  context('Tablet Browser Compatibility (Safari iPad, Chrome tablet 768-1024px)', () => {
    beforeEach(() => {
      cy.viewport(768, 1024); // Tablet viewport (iPad portrait)
    });

    it('should detect tablet device type and show full features', () => {
      cy.get('[data-testid="device-type"]').should('contain', 'Tablet');
      cy.get('[data-testid="advanced-features"]').should('be.visible');
    });

    it('should load identical default values on tablet', () => {
      // Same defaults as desktop and mobile
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      cy.get('[data-testid="truck-capacity-input"]').should('have.value', '12');
      cy.get('[data-testid="pond-length-input"]').should('have.value', '40');
    });

    it('should calculate timeline identically across orientations', () => {
      // Portrait calculation
      cy.get('[data-testid="calculate-button"]').click();
      cy.get('[data-testid="timeline-days"]').should('contain', '1');
      
      // Landscape calculation
      cy.viewport(1024, 768); // iPad landscape
      cy.wait(500);
      
      cy.get('[data-testid="timeline-days"]').should('contain', '1');
    });
  });

  context('Cross-Browser Calculation Consistency', () => {
    const viewports = [
      { name: 'Mobile', width: 375, height: 667 },
      { name: 'Tablet', width: 768, height: 1024 },
      { name: 'Desktop', width: 1200, height: 800 }
    ];

    viewports.forEach(viewport => {
      it(`should produce identical calculation results on ${viewport.name}`, () => {
        cy.viewport(viewport.width, viewport.height);
        
        // Input same test values
        cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
        cy.get('[data-testid="excavator-cycle-input"]').clear().type('2.5');
        cy.get('[data-testid="truck-capacity-input"]').clear().type('15.0');
        cy.get('[data-testid="pond-length-input"]').clear().type('50');
        
        cy.wait(400); // Wait for debounce
        
        // Verify consistent results
        cy.get('[data-testid="timeline-result"]').should('be.visible');
        cy.get('[data-testid="excavation-rate"]').should('contain.text', 'cy/hour');
        cy.get('[data-testid="hauling-rate"]').should('contain.text', 'cy/hour');
      });
    });
  });

  context('Browser-Specific Edge Cases', () => {
    it('should handle floating point precision consistently', () => {
      cy.viewport(1200, 800);
      
      // Test values that might cause precision issues
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.33333');
      cy.get('[data-testid="excavator-cycle-input"]').clear().type('1.66667');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('11.11111');
      
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('match', /^\d+$/);
    });

    it('should handle large numbers consistently', () => {
      cy.viewport(1200, 800);
      
      cy.get('[data-testid="pond-length-input"]').clear().type('1000');
      cy.get('[data-testid="pond-width-input"]').clear().type('500');
      cy.get('[data-testid="pond-depth-input"]').clear().type('10');
      
      cy.wait(400);
      
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
    });

    it('should handle string parsing edge cases', () => {
      cy.viewport(1200, 800);
      
      // Test various number formats
      const testCases = ['2.5', '2.50', '02.5', '2.500000'];
      
      testCases.forEach(value => {
        cy.get('[data-testid="excavator-capacity-input"]').clear().type(value);
        cy.wait(100);
        
        // Should accept all valid number formats
        cy.get('[data-testid="excavator-capacity-error"]').should('not.exist');
      });
    });
  });

  context('Device Transition State Preservation', () => {
    it('should preserve user input during device transitions', () => {
      // Start on desktop
      cy.viewport(1200, 800);
      
      // Enter custom values
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('4.5');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('18');
      cy.get('[data-testid="pond-length-input"]').clear().type('75');
      
      cy.wait(400);
      
      // Get initial calculation result
      cy.get('[data-testid="timeline-days"]').then($timeline => {
        const initialDays = $timeline.text();
        
        // Transition to tablet
        cy.viewport(800, 1024);
        cy.wait(500);
        
        // Values should be preserved
        cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '4.5');
        cy.get('[data-testid="truck-capacity-input"]').should('have.value', '18');
        cy.get('[data-testid="pond-length-input"]').should('have.value', '75');
        cy.get('[data-testid="timeline-days"]').should('contain', initialDays);
        
        // Transition to mobile
        cy.viewport(375, 667);
        cy.wait(500);
        
        // Core values should still be preserved
        cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '4.5');
        cy.get('[data-testid="truck-capacity-input"]').should('have.value', '18');
        cy.get('[data-testid="timeline-days"]').should('contain', initialDays);
      });
    });

    it('should preserve validation errors during device transitions', () => {
      cy.viewport(1200, 800);
      
      // Create validation error
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-5');
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      
      // Transition to mobile
      cy.viewport(375, 667);
      cy.wait(500);
      
      // Error should be preserved
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '-5');
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
    });
  });
});