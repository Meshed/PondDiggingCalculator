/// <reference types="cypress" />

describe('Critical User Journey Tests', () => {
  beforeEach(() => {
    cy.visit('/');
    // Configuration is now loaded at build-time (static) - no HTTP wait needed
  });

  context('Construction Estimator Complete Workflow', () => {
    it('should complete full estimation workflow from start to finish', () => {
      cy.viewport(1200, 800); // Desktop professional workflow
      
      // Verify page loads with defaults
      cy.get('[data-testid="device-type"]').should('contain', 'Desktop');
      
      // Step 1: Professional enters project parameters
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .clear()
        .type('3.0');
        
      cy.get('[data-testid="excavator-cycle-input"]')
        .clear()
        .type('2.5');
        
      cy.get('[data-testid="truck-capacity-input"]')
        .clear()
        .type('15.0');
        
      cy.get('[data-testid="truck-roundtrip-input"]')
        .clear()
        .type('20.0');
        
      // Step 2: Enter specific pond dimensions
      cy.get('[data-testid="pond-length-input"]')
        .clear()
        .type('75');
        
      cy.get('[data-testid="pond-width-input"]')
        .clear()
        .type('45');
        
      cy.get('[data-testid="pond-depth-input"]')
        .clear()
        .type('8');
        
      // Step 3: Adjust work schedule
      cy.get('[data-testid="work-hours-input"]')
        .clear()
        .type('9.5');
        
      // Step 4: Wait for real-time calculation
      cy.wait(400); // Debounce period
      
      // Step 5: Verify comprehensive results display
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
      cy.get('[data-testid="excavation-rate"]').should('be.visible');
      cy.get('[data-testid="hauling-rate"]').should('be.visible');
      cy.get('[data-testid="bottleneck"]').should('be.visible');
      
      // Step 6: Verify calculation accuracy (large pond should take multiple days)
      cy.get('[data-testid="timeline-days"]').then($days => {
        const days = parseInt($days.text());
        expect(days).to.be.greaterThan(1); // Large pond should take multiple days
        expect(days).to.be.lessThan(100); // But reasonable for construction project
      });
      
      // Step 7: Verify contextual information is displayed
      cy.get('[data-testid="timeline-result"]').within(() => {
        cy.contains('cubic yards').should('be.visible');
        cy.contains('day').should('be.visible');
      });
    });

    it('should handle rapid parameter changes during estimation', () => {
      cy.viewport(1200, 800);
      
      // Simulate estimator rapidly adjusting parameters
      const testSequence = [
        { field: 'pond-length-input', value: '50' },
        { field: 'pond-width-input', value: '30' },
        { field: 'excavator-capacity-input', value: '2.8' },
        { field: 'truck-capacity-input', value: '14' },
        { field: 'pond-depth-input', value: '6' }
      ];
      
      testSequence.forEach(({ field, value }, index) => {
        cy.get(`[data-testid="${field}"]`)
          .clear()
          .type(value);
        
        // Small delay to simulate realistic typing
        cy.wait(100);
      });
      
      // Final calculation should still work correctly
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
    });

    it('should provide consistent results for typical small pond project', () => {
      cy.viewport(1200, 800);
      
      // Typical residential pond parameters
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.5');
      cy.get('[data-testid="excavator-cycle-input"]').clear().type('2.0');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('12.0');
      cy.get('[data-testid="truck-roundtrip-input"]').clear().type('15.0');
      cy.get('[data-testid="work-hours-input"]').clear().type('8');
      cy.get('[data-testid="pond-length-input"]').clear().type('30');
      cy.get('[data-testid="pond-width-input"]').clear().type('20');
      cy.get('[data-testid="pond-depth-input"]').clear().type('4');
      
      cy.wait(400);
      
      // Should calculate to reasonable timeline
      cy.get('[data-testid="timeline-days"]').should('be.visible');
      cy.get('[data-testid="excavation-rate"]').should('contain', 'cubic yards');
      cy.get('[data-testid="hauling-rate"]').should('contain', 'cubic yards');
    });
  });

  context('Field Worker Quick Calculation Workflow', () => {
    it('should enable quick mobile calculations on job site', () => {
      cy.viewport(375, 667); // Mobile device
      
      // Verify mobile interface loads
      cy.get('[data-testid="device-type"]').should('contain', 'Mobile');
      cy.get('[data-testid="simplified-interface"]').should('be.visible');
      
      // Step 1: Quick equipment entry (simplified mobile interface)
      cy.get('[data-testid="excavator-capacity-input"]')
        .should('be.visible')
        .clear()
        .type('2.5');
        
      cy.get('[data-testid="truck-capacity-input"]')
        .clear()
        .type('12');
        
      // Step 2: Quick pond measurement entry  
      cy.get('[data-testid="pond-length-input"]')
        .clear()
        .type('40');
        
      cy.get('[data-testid="pond-width-input"]')
        .clear()  
        .type('25');
        
      cy.get('[data-testid="pond-depth-input"]')
        .clear()
        .type('5');
        
      // Step 3: Get instant result
      cy.wait(400);
      
      // Step 4: Verify mobile-optimized results display
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]')
        .should('be.visible')
        .and('have.css', 'font-size')
        .and('match', /24px|1.5rem/); // Large mobile font
        
      // Mobile should show simplified result
      cy.get('[data-testid="timeline-days"]').should('contain', '1');
    });

    it('should maintain calculator-like simplicity on mobile', () => {
      cy.viewport(375, 667);
      
      // Verify clean, simple interface
      cy.get('[data-testid="advanced-features"]').should('not.exist');
      
      // Test clear/reset functionality
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.get('[data-testid="pond-length-input"]').clear().type('60');
      
      // Reset should be easily accessible
      if (cy.get('[data-testid="reset-button"]').should('exist')) {
        cy.get('[data-testid="reset-button"]').click();
        cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
      }
    });
  });

  context('Cross-Device Workflow Consistency', () => {
    it('should maintain calculation accuracy across device transitions', () => {
      // Start on desktop
      cy.viewport(1200, 800);
      
      // Enter parameters
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('16');
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.get('[data-testid="pond-width-input"]').clear().type('30');
      cy.get('[data-testid="pond-depth-input"]').clear().type('6');
      
      cy.wait(400);
      
      // Capture desktop results
      cy.get('[data-testid="timeline-days"]').then($desktopDays => {
        const desktopResult = $desktopDays.text();
        
        // Transition to tablet
        cy.viewport(768, 1024);
        cy.wait(500);
        
        // Verify tablet shows same calculation
        cy.get('[data-testid="timeline-days"]').should('contain', desktopResult);
        
        // Transition to mobile
        cy.viewport(375, 667);
        cy.wait(500);
        
        // Verify mobile shows same core result
        cy.get('[data-testid="timeline-days"]').should('contain', desktopResult);
      });
    });

    it('should preserve user inputs during responsive transitions', () => {
      cy.viewport(1200, 800);
      
      const testData = {
        excavatorCapacity: '4.0',
        truckCapacity: '18',
        pondLength: '75',
        pondWidth: '45',
        pondDepth: '8'
      };
      
      // Fill form on desktop
      Object.entries(testData).forEach(([field, value]) => {
        const fieldName = field.replace(/([A-Z])/g, '-$1').toLowerCase();
        cy.get(`[data-testid="${fieldName}-input"]`).clear().type(value);
      });
      
      // Transition through device sizes
      const viewports = [
        { width: 768, height: 1024 }, // Tablet
        { width: 375, height: 667 },  // Mobile
        { width: 1200, height: 800 }  // Back to desktop
      ];
      
      viewports.forEach(viewport => {
        cy.viewport(viewport.width, viewport.height);
        cy.wait(500);
        
        // Verify data preservation
        cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '4.0');
        cy.get('[data-testid="truck-capacity-input"]').should('have.value', '18');
        cy.get('[data-testid="pond-length-input"]').should('have.value', '75');
      });
    });
  });

  context('Real-World Usage Scenarios', () => {
    it('should handle typical contractor estimation workflow', () => {
      cy.viewport(1200, 800);
      
      // Scenario: Contractor estimating medium commercial pond
      const projectParams = {
        excavatorCapacity: '3.5',
        excavatorCycle: '2.2',
        truckCapacity: '16.0', 
        truckRoundTrip: '25.0',
        workHours: '10.0',
        pondLength: '100',
        pondWidth: '60', 
        pondDepth: '10'
      };
      
      // Fill realistic parameters
      Object.entries(projectParams).forEach(([field, value]) => {
        const fieldName = field.replace(/([A-Z])/g, '-$1').toLowerCase();
        cy.get(`[data-testid="${fieldName}-input"]`).clear().type(value);
      });
      
      cy.wait(400);
      
      // Verify realistic timeline for large project
      cy.get('[data-testid="timeline-days"]').then($days => {
        const days = parseInt($days.text());
        expect(days).to.be.greaterThan(3); // Large commercial pond takes multiple days
        expect(days).to.be.lessThan(30);   // But not unreasonably long
      });
      
      // Verify bottleneck identification
      cy.get('[data-testid="bottleneck"]').should('be.visible');
      cy.get('[data-testid="excavation-rate"]').should('be.visible');
      cy.get('[data-testid="hauling-rate"]').should('be.visible');
    });

    it('should handle equipment optimization scenarios', () => {
      cy.viewport(1200, 800);
      
      // Scenario: Compare different equipment configurations
      const baseProject = {
        pondLength: '60',
        pondWidth: '40',
        pondDepth: '6',
        workHours: '8'
      };
      
      // Set base project parameters
      Object.entries(baseProject).forEach(([field, value]) => {
        const fieldName = field.replace(/([A-Z])/g, '-$1').toLowerCase();
        cy.get(`[data-testid="${fieldName}-input"]`).clear().type(value);
      });
      
      // Test Scenario A: Small equipment
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.0');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('10');
      cy.wait(400);
      
      cy.get('[data-testid="timeline-days"]').then($daysA => {
        const daysSmallEquipment = parseInt($daysA.text());
        
        // Test Scenario B: Large equipment
        cy.get('[data-testid="excavator-capacity-input"]').clear().type('4.0');
        cy.get('[data-testid="truck-capacity-input"]').clear().type('20');
        cy.wait(400);
        
        cy.get('[data-testid="timeline-days"]').then($daysB => {
          const daysLargeEquipment = parseInt($daysB.text());
          
          // Large equipment should be faster or same (never slower)
          expect(daysLargeEquipment).to.be.at.most(daysSmallEquipment);
        });
      });
    });

    it('should validate professional edge cases', () => {
      cy.viewport(1200, 800);
      
      // Test very shallow pond (drainage/retention pond)
      cy.get('[data-testid="pond-length-input"]').clear().type('200');
      cy.get('[data-testid="pond-width-input"]').clear().type('100');
      cy.get('[data-testid="pond-depth-input"]').clear().type('2');
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      
      cy.wait(400);
      
      // Should handle large, shallow excavation
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
      
      // Test deep, narrow pond (well/sump)
      cy.get('[data-testid="pond-length-input"]').clear().type('15');
      cy.get('[data-testid="pond-width-input"]').clear().type('15');
      cy.get('[data-testid="pond-depth-input"]').clear().type('12');
      
      cy.wait(400);
      
      // Should handle deep, small excavation
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="timeline-days"]').should('be.visible');
    });
  });

  context('Error Recovery and Validation Workflow', () => {
    it('should guide user through validation errors', () => {
      cy.viewport(1200, 800);
      
      // Create validation errors
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('0');
      cy.get('[data-testid="pond-depth-input"]').clear().type('abc');
      
      // Verify errors are displayed
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      cy.get('[data-testid="truck-capacity-error"]').should('be.visible');
      cy.get('[data-testid="pond-depth-error"]').should('be.visible');
      
      // Verify no calculation during error state
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      // Fix errors one by one
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('2.5');
      cy.get('[data-testid="excavator-capacity-error"]').should('not.exist');
      
      cy.get('[data-testid="truck-capacity-input"]').clear().type('12');
      cy.get('[data-testid="truck-capacity-error"]').should('not.exist');
      
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      cy.get('[data-testid="pond-depth-error"]').should('not.exist');
      
      // Calculation should resume
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });
});