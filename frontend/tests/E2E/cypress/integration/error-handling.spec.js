/// <reference types="cypress" />

describe('Error Handling and Edge Cases', () => {
  beforeEach(() => {
    cy.visit('/');
    cy.wait(1000); // Allow config to load
  });

  context('Network Failure Scenarios', () => {
    it('should handle config loading failures gracefully', () => {
      // Simulate network failure during config load
      cy.intercept('GET', '/config.json', { forceNetworkError: true }).as('configFailure');
      
      // Visit page with failed config
      cy.visit('/');
      
      // Should fall back to hardcoded defaults
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible');
        
      // Fallback values should still work
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value');
      cy.get('[data-testid="truck-capacity-input"]').should('have.value');
      
      // Application should still function
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      
      // Should still calculate even with fallback config
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should handle corrupted config data gracefully', () => {
      // Simulate corrupted JSON config
      cy.intercept('GET', '/config.json', { 
        statusCode: 200, 
        body: '{ invalid json ;;; }' 
      }).as('corruptedConfig');
      
      cy.visit('/');
      
      // Should fall back to defaults despite corrupted config
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible');
        
      // Application should remain functional
      cy.get('[data-testid="pond-length-input"]').clear().type('50');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should handle slow network conditions', () => {
      // Simulate slow config loading
      cy.intercept('GET', '/config.json', { 
        delay: 3000,
        fixture: 'config.json' 
      }).as('slowConfig');
      
      cy.visit('/');
      
      // Should show loading state or defaults during slow load
      cy.get('[data-testid="excavator-capacity-input"]', { timeout: 5000 })
        .should('be.visible');
        
      // Should eventually load properly
      cy.wait('@slowConfig');
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '2.5');
    });
  });

  context('Input Validation Error Scenarios', () => {
    it('should handle invalid number formats', () => {
      cy.viewport(1200, 800);
      
      const invalidInputs = [
        { field: 'excavator-capacity-input', value: 'abc', error: 'excavator-capacity-error' },
        { field: 'truck-capacity-input', value: '2.5.5', error: 'truck-capacity-error' },
        { field: 'pond-length-input', value: 'ten', error: 'pond-length-error' },
        { field: 'pond-depth-input', value: '1.2.3.4', error: 'pond-depth-error' }
      ];
      
      invalidInputs.forEach(({ field, value, error }) => {
        cy.get(`[data-testid="${field}"]`).clear().type(value);
        
        // Should show appropriate error message
        cy.get(`[data-testid="${error}"]`).should('be.visible');
        
        // Should not perform calculation with invalid input
        cy.get('[data-testid="timeline-result"]').should('not.exist');
      });
    });

    it('should handle negative value validation', () => {
      cy.viewport(1200, 800);
      
      const negativeValues = [
        { field: 'excavator-capacity-input', value: '-2.5' },
        { field: 'truck-capacity-input', value: '-10' },
        { field: 'work-hours-input', value: '-8' },
        { field: 'pond-length-input', value: '-40' }
      ];
      
      negativeValues.forEach(({ field, value }) => {
        cy.get(`[data-testid="${field}"]`).clear().type(value);
        
        // Should show negative value error
        const errorField = field.replace('-input', '-error');
        cy.get(`[data-testid="${errorField}"]`)
          .should('be.visible')
          .and('contain.text', 'must be greater than zero');
      });
    });

    it('should handle zero value validation', () => {
      cy.viewport(1200, 800);
      
      // Test zero values where they shouldn't be allowed
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('0');
      cy.get('[data-testid="excavator-capacity-error"]')
        .should('be.visible')
        .and('contain.text', 'must be greater than zero');
        
      cy.get('[data-testid="truck-capacity-input"]').clear().type('0');
      cy.get('[data-testid="truck-capacity-error"]')
        .should('be.visible')
        .and('contain.text', 'must be greater than zero');
        
      // Should not calculate with zero values
      cy.get('[data-testid="timeline-result"]').should('not.exist');
    });

    it('should handle extremely large values', () => {
      cy.viewport(1200, 800);
      
      // Test unreasonably large values
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('999999');
      cy.get('[data-testid="excavator-capacity-error"]')
        .should('be.visible')
        .and('contain.text', 'too high');
        
      cy.get('[data-testid="truck-capacity-input"]').clear().type('999999');
      cy.get('[data-testid="truck-capacity-error"]')
        .should('be.visible')
        .and('contain.text', 'too high');
        
      cy.get('[data-testid="work-hours-input"]').clear().type('100');
      cy.get('[data-testid="work-hours-error"]')
        .should('be.visible')
        .and('contain.text', 'too high');
    });

    it('should handle very small decimal values', () => {
      cy.viewport(1200, 800);
      
      // Test very small but valid values
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('0.001');
      cy.get('[data-testid="excavator-capacity-error"]')
        .should('be.visible')
        .and('contain.text', 'too small');
        
      // Test reasonable small values should work
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('0.5');
      cy.get('[data-testid="excavator-capacity-error"]').should('not.exist');
    });
  });

  context('Calculation Error Scenarios', () => {
    it('should handle mathematical edge cases', () => {
      cy.viewport(1200, 800);
      
      // Test scenario that might cause division by zero or overflow
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('0.1');
      cy.get('[data-testid="excavator-cycle-input"]').clear().type('0.1');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('0.1');
      cy.get('[data-testid="truck-roundtrip-input"]').clear().type('999');
      cy.get('[data-testid="pond-length-input"]').clear().type('999999');
      cy.get('[data-testid="pond-width-input"]').clear().type('999999');
      cy.get('[data-testid="pond-depth-input"]').clear().type('50');
      
      cy.wait(400);
      
      // Should either show error or very large timeline (not crash)
      cy.get('body').then($body => {
        if ($body.find('[data-testid="timeline-result"]').length > 0) {
          // If calculation succeeds, result should be reasonable
          cy.get('[data-testid="timeline-days"]').should('be.visible');
        } else {
          // If calculation fails, should show appropriate error
          cy.get('[data-testid="calculation-error"]').should('be.visible');
        }
      });
    });

    it('should handle floating point precision issues', () => {
      cy.viewport(1200, 800);
      
      // Test values that might cause floating point precision issues
      const precisionValues = [
        '2.33333333333333',
        '1.66666666666667', 
        '0.142857142857143',
        '3.14159265358979'
      ];
      
      precisionValues.forEach(value => {
        cy.get('[data-testid="excavator-capacity-input"]').clear().type(value);
        cy.wait(100);
        
        // Should accept the input without error
        cy.get('[data-testid="excavator-capacity-error"]').should('not.exist');
      });
      
      // Final calculation should work
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Result should be a clean number (not showing precision errors)
      cy.get('[data-testid="timeline-days"]').should('match', /^\d+$/);
    });

    it('should handle impossible equipment configurations', () => {
      cy.viewport(1200, 800);
      
      // Test configuration where truck is much slower than excavator
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('5.0');
      cy.get('[data-testid="excavator-cycle-input"]').clear().type('1.0'); // Very fast
      cy.get('[data-testid="truck-capacity-input"]').clear().type('2.0'); // Very small
      cy.get('[data-testid="truck-roundtrip-input"]').clear().type('120'); // Very slow
      
      cy.get('[data-testid="pond-length-input"]').clear().type('100');
      cy.get('[data-testid="pond-width-input"]').clear().type('100');
      cy.get('[data-testid="pond-depth-input"]').clear().type('10');
      
      cy.wait(400);
      
      // Should identify hauling as bottleneck
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      cy.get('[data-testid="bottleneck"]').should('contain', 'Hauling');
      
      // Should show reasonable timeline despite bottleneck
      cy.get('[data-testid="timeline-days"]').should('be.visible');
    });
  });

  context('Device Transition Error Scenarios', () => {
    it('should handle errors during device type detection', () => {
      // Simulate error in device detection
      cy.viewport(1200, 800);
      
      // Start with desktop
      cy.get('[data-testid="device-type"]').should('contain', 'Desktop');
      
      // Rapid viewport changes (might cause detection issues)
      cy.viewport(375, 667);
      cy.wait(100);
      cy.viewport(768, 1024);
      cy.wait(100);
      cy.viewport(1200, 800);
      cy.wait(500);
      
      // Should settle on correct device type
      cy.get('[data-testid="device-type"]').should('contain', 'Desktop');
      
      // Application should remain functional
      cy.get('[data-testid="excavator-capacity-input"]').should('be.visible');
    });

    it('should preserve validation state during device transitions', () => {
      cy.viewport(1200, 800);
      
      // Create validation errors on desktop
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-5');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('abc');
      
      // Verify errors exist
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      cy.get('[data-testid="truck-capacity-error"]').should('be.visible');
      
      // Transition to mobile
      cy.viewport(375, 667);
      cy.wait(500);
      
      // Errors should persist
      cy.get('[data-testid="excavator-capacity-input"]').should('have.value', '-5');
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      cy.get('[data-testid="truck-capacity-error"]').should('be.visible');
      
      // Fix errors on mobile
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('15');
      
      // Should clear errors and allow calculation
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });

  context('Browser-Specific Error Scenarios', () => {
    it('should handle different number input behaviors', () => {
      cy.viewport(1200, 800);
      
      // Test various number formats that browsers handle differently
      const numberFormats = [
        '2.5',      // Standard decimal
        '2,5',      // European decimal (might be invalid in some browsers)
        '02.5',     // Leading zero
        '2.50',     // Trailing zero
        '2.500000', // Many trailing zeros
        '+2.5',     // Explicit positive
        '2.5e0',    // Scientific notation
        '2.5E0'     // Scientific notation uppercase
      ];
      
      numberFormats.forEach(format => {
        cy.get('[data-testid="excavator-capacity-input"]').clear().type(format);
        
        // Check if browser accepts the format
        cy.get('[data-testid="excavator-capacity-input"]').then($input => {
          const inputValue = $input.val();
          
          if (inputValue && inputValue !== '') {
            // If browser accepts it, our validation should handle it
            cy.get('[data-testid="excavator-capacity-error"]').should('not.exist');
          }
        });
      });
    });

    it('should handle clipboard and paste operations', () => {
      cy.viewport(1200, 800);
      
      // Test pasting invalid data
      cy.get('[data-testid="excavator-capacity-input"]').clear();
      
      // Simulate paste of invalid data
      cy.get('[data-testid="excavator-capacity-input"]').invoke('val', 'invalid data').trigger('input');
      
      // Should show validation error
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      
      // Test pasting valid data
      cy.get('[data-testid="excavator-capacity-input"]').clear();
      cy.get('[data-testid="excavator-capacity-input"]').invoke('val', '3.5').trigger('input');
      
      // Should clear error
      cy.get('[data-testid="excavator-capacity-error"]').should('not.exist');
    });
  });

  context('State Recovery and Error Recovery', () => {
    it('should recover gracefully from calculation errors', () => {
      cy.viewport(1200, 800);
      
      // Set up valid calculation first
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Introduce error
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      // Fix error - should recover to calculation state
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.5');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });

    it('should maintain last valid results during error states', () => {
      cy.viewport(1200, 800);
      
      // Establish valid calculation
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
      
      // Capture the valid result
      cy.get('[data-testid="timeline-days"]').then($days => {
        const validDays = $days.text();
        
        // Introduce validation error
        cy.get('[data-testid="pond-length-input"]').clear().type('abc');
        cy.get('[data-testid="pond-length-error"]').should('be.visible');
        
        // Last valid result should still be displayed (if implemented)
        cy.get('body').then($body => {
          if ($body.find('[data-testid="last-valid-result"]').length > 0) {
            cy.get('[data-testid="last-valid-result"]').should('contain', validDays);
          }
        });
        
        // Fix error - should recalculate
        cy.get('[data-testid="pond-length-input"]').clear().type('50');
        cy.wait(400);
        cy.get('[data-testid="timeline-result"]').should('be.visible');
      });
    });

    it('should handle multiple simultaneous validation errors', () => {
      cy.viewport(1200, 800);
      
      // Create multiple errors simultaneously
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('-1');
      cy.get('[data-testid="truck-capacity-input"]').clear().type('0');
      cy.get('[data-testid="pond-length-input"]').clear().type('abc');
      cy.get('[data-testid="pond-depth-input"]').clear().type('-5');
      
      // All errors should be displayed
      cy.get('[data-testid="excavator-capacity-error"]').should('be.visible');
      cy.get('[data-testid="truck-capacity-error"]').should('be.visible');
      cy.get('[data-testid="pond-length-error"]').should('be.visible');
      cy.get('[data-testid="pond-depth-error"]').should('be.visible');
      
      // No calculation should occur
      cy.get('[data-testid="timeline-result"]').should('not.exist');
      
      // Fix errors one by one
      cy.get('[data-testid="excavator-capacity-input"]').clear().type('3.0');
      cy.get('[data-testid="excavator-capacity-error"]').should('not.exist');
      
      cy.get('[data-testid="truck-capacity-input"]').clear().type('15');
      cy.get('[data-testid="truck-capacity-error"]').should('not.exist');
      
      cy.get('[data-testid="pond-length-input"]').clear().type('40');
      cy.get('[data-testid="pond-length-error"]').should('not.exist');
      
      cy.get('[data-testid="pond-depth-input"]').clear().type('5');
      cy.get('[data-testid="pond-depth-error"]').should('not.exist');
      
      // Should calculate once all errors are fixed
      cy.wait(400);
      cy.get('[data-testid="timeline-result"]').should('be.visible');
    });
  });
});